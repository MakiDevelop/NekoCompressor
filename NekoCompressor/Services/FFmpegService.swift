//
//  FFmpegService.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation
import os.log

/// ffmpeg 壓縮服務
actor FFmpegService {

    private var currentProcess: Process?

    /// 壓縮影片
    /// - Parameters:
    ///   - videoInfo: 影片資訊
    ///   - settings: 壓縮設定
    ///   - outputURL: 輸出路徑
    ///   - isPreview: 是否為預覽模式
    /// - Returns: AsyncStream 回傳進度更新
    func compress(
        videoInfo: VideoInfo,
        settings: CompressionSettings,
        outputURL: URL,
        isPreview: Bool = false
    ) -> AsyncThrowingStream<CompressionProgress, Error> {

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // 檢查 ffmpeg 路徑
                    guard let ffmpegPath = FFmpegPathManager.ffmpegPath() else {
                        continuation.finish(throwing: CompressionError.ffmpegNotFound)
                        return
                    }

                    // 建立命令
                    let arguments = FFmpegCommandBuilder.buildArguments(
                        inputURL: videoInfo.filePath,
                        outputURL: outputURL,
                        settings: settings,
                        videoInfo: videoInfo,
                        isPreview: isPreview
                    )

                    // 記錄 ffmpeg 命令
                    let commandString = ([ffmpegPath.path] + arguments).joined(separator: " ")
                    os_log("[FFmpegService] Executing: %{public}@", log: .default, type: .info, commandString)

                    // 建立 Process
                    let process = Process()
                    process.executableURL = ffmpegPath
                    process.arguments = arguments

                    // 儲存 process 以便取消
                    await setCurrentProcess(process)

                    // 建立 Pipe
                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe

                    // 累積錯誤輸出
                    var errorOutput = ""

                    // 監聽錯誤輸出（ffmpeg 的進度資訊在 stderr）
                    let errorHandle = errorPipe.fileHandleForReading
                    errorHandle.readabilityHandler = { fileHandle in
                        let data = fileHandle.availableData
                        if data.count > 0, let output = String(data: data, encoding: .utf8) {
                            // 累積輸出以便錯誤時使用
                            errorOutput += output

                            // 解析進度
                            if let progress = self.parseProgress(from: output, videoInfo: videoInfo) {
                                continuation.yield(progress)
                            }
                        }
                    }

                    // 執行
                    try process.run()

                    // 等待完成
                    process.waitUntilExit()

                    // 停止監聽
                    errorHandle.readabilityHandler = nil

                    // 檢查結果
                    if process.terminationStatus == 0 {
                        // 成功完成
                        os_log("[FFmpegService] Compression completed successfully", log: .default, type: .info)
                        continuation.finish()
                    } else if process.terminationReason == .uncaughtSignal {
                        // 被取消
                        os_log("[FFmpegService] Compression cancelled", log: .default, type: .info)
                        continuation.finish(throwing: CompressionError.cancelled)
                    } else {
                        // 編碼失敗
                        let errorMessage = errorOutput.isEmpty ? "Unknown error" : errorOutput
                        os_log("[FFmpegService] Compression failed with status %d: %{public}@", log: .default, type: .error, process.terminationStatus, errorMessage)
                        continuation.finish(throwing: CompressionError.encodingFailed(errorMessage))
                    }

                    // 清理
                    await setCurrentProcess(nil)

                } catch {
                    continuation.finish(throwing: error)
                    await setCurrentProcess(nil)
                }
            }
        }
    }

    /// 取消當前壓縮
    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
    }

    /// 設定當前 Process
    private func setCurrentProcess(_ process: Process?) {
        currentProcess = process
    }

    /// 解析 ffmpeg 進度輸出
    /// - Parameters:
    ///   - output: ffmpeg stderr 輸出
    ///   - videoInfo: 影片資訊
    /// - Returns: 壓縮進度
    nonisolated private func parseProgress(from output: String, videoInfo: VideoInfo) -> CompressionProgress? {
        // ffmpeg 進度格式範例：
        // frame=  123 fps= 45 q=28.0 size=    1024kB time=00:00:05.12 bitrate=1638.4kbits/s speed=1.87x

        var currentFrame: Int?
        var fps: Double?
        var bitrate: String?
        var timeSeconds: Double?

        // 使用正則表達式解析
        let patterns: [String: String] = [
            "frame": #"frame=\s*(\d+)"#,
            "fps": #"fps=\s*([\d.]+)"#,
            "bitrate": #"bitrate=\s*([\d.]+\w+/s)"#,
            "time": #"time=(\d{2}):(\d{2}):([\d.]+)"#
        ]

        // 解析 frame
        if let regex = try? NSRegularExpression(pattern: patterns["frame"]!),
           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            currentFrame = Int(output[range])
        }

        // 解析 fps
        if let regex = try? NSRegularExpression(pattern: patterns["fps"]!),
           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            fps = Double(output[range])
        }

        // 解析 bitrate
        if let regex = try? NSRegularExpression(pattern: patterns["bitrate"]!),
           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            bitrate = String(output[range])
        }

        // 解析 time
        if let regex = try? NSRegularExpression(pattern: patterns["time"]!),
           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)) {

            if let hoursRange = Range(match.range(at: 1), in: output),
               let minutesRange = Range(match.range(at: 2), in: output),
               let secondsRange = Range(match.range(at: 3), in: output),
               let hours = Int(output[hoursRange]),
               let minutes = Int(output[minutesRange]),
               let seconds = Double(output[secondsRange]) {
                timeSeconds = Double(hours * 3600 + minutes * 60) + seconds
            }
        }

        // 如果有有效的進度資訊，建立 CompressionProgress
        if let frame = currentFrame, let time = timeSeconds {
            let totalFrames = Int(videoInfo.duration * videoInfo.fps)

            return CompressionProgress(
                currentFrame: frame,
                totalFrames: totalFrames,
                currentTime: time,
                totalDuration: videoInfo.duration,
                fps: fps ?? 0,
                bitrate: bitrate ?? "0kbits/s"
            )
        }

        return nil
    }
}
