//
//  ProbeService.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation
import os.log

/// ffprobe 服務，用於解析影片資訊
actor ProbeService {

    enum ProbeError: LocalizedError {
        case ffprobeNotFound
        case invalidVideoFile
        case decodeFailed(String)
        case executionFailed(String)

        var errorDescription: String? {
            switch self {
            case .ffprobeNotFound:
                return "找不到 ffprobe 執行檔"
            case .invalidVideoFile:
                return "無效的影片檔案"
            case .decodeFailed(let message):
                return "解析失敗：\(message)"
            case .executionFailed(let message):
                return "執行失敗：\(message)"
            }
        }
    }

    /// 解析影片資訊
    /// - Parameter url: 影片檔案路徑
    /// - Returns: VideoInfo 物件
    func probe(videoURL: URL) async throws -> VideoInfo {
        guard let ffprobePath = FFmpegPathManager.ffprobePath() else {
            throw ProbeError.ffprobeNotFound
        }

        // 驗證檔案存在
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw ProbeError.invalidVideoFile
        }

        // 建立 Process
        let process = Process()
        process.executableURL = ffprobePath
        process.arguments = [
            "-v", "quiet",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            videoURL.path
        ]

        // 建立 Pipe 接收輸出
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // 執行
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw ProbeError.executionFailed(error.localizedDescription)
        }

        // 檢查執行結果
        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ProbeError.executionFailed(errorMessage)
        }

        // 讀取輸出
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        // 記錄原始輸出（用於除錯）
        if let outputString = String(data: outputData, encoding: .utf8) {
            os_log("[ProbeService] ffprobe output length: %d bytes", log: .default, type: .debug, outputString.count)
            if outputData.isEmpty {
                os_log("[ProbeService] ERROR: ffprobe output is empty!", log: .default, type: .error)
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "No error message"
                os_log("[ProbeService] ffprobe stderr: %{public}@", log: .default, type: .error, errorMessage)
                throw ProbeError.executionFailed("ffprobe 輸出為空。錯誤：\(errorMessage)")
            }
            os_log("[ProbeService] ffprobe output: %{public}@", log: .default, type: .debug, String(outputString.prefix(500)))
        }

        // 解析 JSON
        do {
            let probeResult = try JSONDecoder().decode(FFProbeResult.self, from: outputData)
            return try parseVideoInfo(from: probeResult, url: videoURL)
        } catch {
            os_log("[ProbeService] JSON decode error: %{public}@", log: .default, type: .error, error.localizedDescription)
            if let outputString = String(data: outputData, encoding: .utf8) {
                os_log("[ProbeService] Raw output for debugging: %{public}@", log: .default, type: .error, outputString)
            }
            throw ProbeError.decodeFailed("JSON 解析失敗：\(error.localizedDescription)")
        }
    }

    /// 從 ffprobe 結果解析 VideoInfo
    private func parseVideoInfo(from result: FFProbeResult, url: URL) throws -> VideoInfo {
        // 取得影片串流
        guard let videoStream = result.streams.first(where: { $0.codecType == "video" }) else {
            throw ProbeError.invalidVideoFile
        }

        // 取得音訊串流
        let audioStream = result.streams.first(where: { $0.codecType == "audio" })

        // 解析時長
        let duration: Double
        if let durationStr = result.format.duration, let durationValue = Double(durationStr) {
            duration = durationValue
        } else if let streamDuration = videoStream.duration, let durationValue = Double(streamDuration) {
            duration = durationValue
        } else {
            duration = 0
        }

        // 解析碼率
        let bitrate: Int64
        if let bitrateStr = result.format.bitrate, let bitrateValue = Int64(bitrateStr) {
            bitrate = bitrateValue
        } else if let streamBitrate = videoStream.bitrate, let bitrateValue = Int64(streamBitrate) {
            bitrate = bitrateValue
        } else {
            bitrate = 0
        }

        // 解析 FPS
        let fps: Double
        if let fpsStr = videoStream.rFrameRate {
            let components = fpsStr.split(separator: "/")
            if components.count == 2,
               let numerator = Double(components[0]),
               let denominator = Double(components[1]),
               denominator != 0 {
                fps = numerator / denominator
            } else {
                fps = 30.0 // 預設值
            }
        } else {
            fps = 30.0
        }

        // 取得檔案大小
        let fileSize: Int64
        if let sizeStr = result.format.size, let sizeValue = Int64(sizeStr) {
            fileSize = sizeValue
        } else {
            // 從檔案系統取得
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? Int64 {
                fileSize = size
            } else {
                fileSize = 0
            }
        }

        // 確保影片串流有寬高和編碼資訊
        guard let width = videoStream.width,
              let height = videoStream.height,
              let videoCodec = videoStream.codecName else {
            throw ProbeError.invalidVideoFile
        }

        return VideoInfo(
            filePath: url,
            fileSize: fileSize,
            duration: duration,
            width: width,
            height: height,
            fps: fps,
            bitrate: bitrate,
            format: result.format.formatName,
            audioCodec: audioStream?.codecName,
            videoCodec: videoCodec
        )
    }
}

// MARK: - FFProbe JSON 結構

/// ffprobe JSON 輸出結構
private struct FFProbeResult: Codable {
    let streams: [FFProbeStream]
    let format: FFProbeFormat
}

/// ffprobe 串流資訊
private struct FFProbeStream: Codable {
    let codecName: String?
    let codecType: String
    let width: Int?
    let height: Int?
    let rFrameRate: String?
    let duration: String?
    let bitrate: String?

    enum CodingKeys: String, CodingKey {
        case codecName = "codec_name"
        case codecType = "codec_type"
        case width
        case height
        case rFrameRate = "r_frame_rate"
        case duration
        case bitrate = "bit_rate"
    }
}

/// ffprobe 格式資訊
private struct FFProbeFormat: Codable {
    let formatName: String
    let duration: String?
    let size: String?
    let bitrate: String?

    enum CodingKeys: String, CodingKey {
        case formatName = "format_name"
        case duration
        case size
        case bitrate = "bit_rate"
    }
}
