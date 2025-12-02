//
//  MainViewModel.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation
import SwiftUI
import Combine
import os.log
import UniformTypeIdentifiers

/// 應用程式狀態
enum AppState {
    case idle              // 閒置，等待匯入影片
    case analyzing         // 正在分析影片
    case ready             // 已匯入影片，準備壓縮
    case compressing       // 正在壓縮
    case completed         // 壓縮完成
    case error(String)     // 發生錯誤
}

/// 主視圖模型
@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var appState: AppState = .idle
    @Published var videoInfo: VideoInfo?
    @Published var compressionProgress: CompressionProgress?
    @Published var outputURL: URL?
    @Published var logs: [LogEntry] = []

    // MARK: - Output Settings

    @Published var customOutputDirectory: URL?
    @Published var useCustomOutputDirectory: Bool = false
    @Published var customFilename: String = ""
    @Published var useCustomFilename: Bool = false

    // MARK: - Compression Settings

    @Published var selectedMode: CompressionMode = .crf
    @Published var selectedCodec: VideoCodec = .h264

    // CRF Settings
    @Published var crfValue: Int = 23
    @Published var crfPreset: EncodingPreset = .medium

    // Target Size Settings
    @Published var targetSizeMB: Double = 50
    @Published var includeAudio: Bool = true
    @Published var audioBitrate: Int = 128

    // Resolution Settings
    @Published var targetResolution: ResolutionPreset = .p1080
    @Published var targetFPS: Int? = nil
    @Published var resolutionPreset: EncodingPreset = .medium
    @Published var maintainAspectRatio: Bool = true

    // Advanced Settings
    @Published var overwriteExisting: Bool = false
    @Published var keepMetadata: Bool = true

    // MARK: - Services

    private let probeService = ProbeService()
    private let ffmpegService = FFmpegService()

    // MARK: - Computed Properties

    /// 當前壓縮設定
    var currentSettings: CompressionSettings {
        var settings = CompressionSettings(
            mode: selectedMode,
            codec: selectedCodec
        )

        switch selectedMode {
        case .crf:
            settings.crfSettings = CRFSettings(
                crfValue: crfValue,
                preset: crfPreset
            )

        case .targetSize:
            settings.targetSizeSettings = TargetSizeSettings(
                targetSizeMB: targetSizeMB,
                includeAudio: includeAudio,
                audioBitrate: audioBitrate
            )

        case .resolution:
            settings.resolutionSettings = ResolutionSettings(
                targetResolution: targetResolution,
                targetFPS: targetFPS,
                preset: resolutionPreset,
                audioBitrate: audioBitrate,
                maintainAspectRatio: maintainAspectRatio
            )
        }

        return settings
    }

    /// 是否可以開始壓縮
    var canStartCompression: Bool {
        if case .ready = appState {
            return videoInfo != nil
        }
        return false
    }

    /// 是否正在壓縮
    var isCompressing: Bool {
        if case .compressing = appState {
            return true
        }
        return false
    }

    // MARK: - Video Import

    /// 匯入影片
    func importVideo(url: URL) async {
        log("開始匯入影片：\(url.lastPathComponent)", level: .info)
        appState = .analyzing

        do {
            let info = try await probeService.probe(videoURL: url)
            videoInfo = info
            log("影片解析成功：\(info.resolutionFormatted), \(info.durationFormatted), \(info.fileSizeFormatted)", level: .info)
            appState = .ready
        } catch {
            let errorMsg = "無法解析影片：\(error.localizedDescription)"
            log(errorMsg, level: .error)
            appState = .error(errorMsg)
        }
    }

    /// 重新匯入影片
    func resetVideo() {
        log("重置狀態", level: .info)
        videoInfo = nil
        compressionProgress = nil
        outputURL = nil
        logs.removeAll()
        appState = .idle
    }

    // MARK: - Compression

    /// 開始壓縮
    func startCompression() async {
        guard let videoInfo = videoInfo else {
            let errorMsg = "尚未匯入影片"
            log(errorMsg, level: .error)
            appState = .error(errorMsg)
            return
        }

        // 如果有自訂輸出目錄，直接使用；否則顯示儲存對話框
        let output: URL
        if useCustomOutputDirectory, let customDir = customOutputDirectory {
            output = generateOutputURL(for: videoInfo)
        } else {
            // 顯示儲存對話框
            guard let selectedURL = showSavePanel(for: videoInfo) else {
                log("使用者取消儲存", level: .info)
                return
            }
            output = selectedURL
        }

        outputURL = output

        log("開始壓縮：\(selectedMode.rawValue), 編碼器：\(selectedCodec.rawValue)", level: .info)
        log("輸出路徑：\(output.path)", level: .info)

        appState = .compressing
        compressionProgress = nil

        do {
            let stream = await ffmpegService.compress(
                videoInfo: videoInfo,
                settings: currentSettings,
                outputURL: output
            )

            for try await progress in stream {
                compressionProgress = progress
            }

            // 壓縮完成
            log("壓縮完成：\(output.lastPathComponent)", level: .info)
            appState = .completed

        } catch let error as CompressionError {
            if case .cancelled = error {
                log("壓縮已取消", level: .warning)
                appState = .ready
            } else {
                log("壓縮失敗：\(error.localizedDescription)", level: .error)
                appState = .error(error.localizedDescription)
            }
        } catch {
            let errorMsg = "壓縮失敗：\(error.localizedDescription)"
            log(errorMsg, level: .error)
            appState = .error(errorMsg)
        }
    }

    /// 取消壓縮
    func cancelCompression() async {
        log("取消壓縮", level: .warning)
        await ffmpegService.cancel()
        compressionProgress = nil
        appState = .ready
    }

    /// 生成輸出檔案 URL
    private func generateOutputURL(for videoInfo: VideoInfo) -> URL {
        let inputURL = videoInfo.filePath

        // 決定輸出目錄
        let directory: URL
        if useCustomOutputDirectory, let customDir = customOutputDirectory {
            directory = customDir
        } else {
            // 使用暫存目錄（沙盒應用程式有完整權限）
            directory = FileManager.default.temporaryDirectory
        }

        // 決定檔名
        let baseFilename: String
        if useCustomFilename && !customFilename.isEmpty {
            baseFilename = customFilename
        } else {
            baseFilename = inputURL.deletingPathExtension().lastPathComponent

            // 根據模式生成檔名後綴
            let suffix: String
            switch selectedMode {
            case .crf:
                suffix = "-crf\(crfValue)"
            case .targetSize:
                suffix = "-\(Int(targetSizeMB))mb"
            case .resolution:
                suffix = "-\(targetResolution.rawValue.replacingOccurrences(of: " ", with: ""))"
            }

            return generateUniqueURL(
                in: directory,
                baseName: baseFilename + suffix,
                extension: "mp4"
            )
        }

        return generateUniqueURL(
            in: directory,
            baseName: baseFilename,
            extension: "mp4"
        )
    }

    /// 生成唯一的檔案 URL（避免覆寫）
    private func generateUniqueURL(in directory: URL, baseName: String, extension ext: String) -> URL {
        var outputFilename = "\(baseName).\(ext)"
        var outputURL = directory.appendingPathComponent(outputFilename)

        // 如果允許覆寫，直接返回
        if overwriteExisting {
            return outputURL
        }

        // 避免檔名衝突
        var counter = 1
        while FileManager.default.fileExists(atPath: outputURL.path) {
            outputFilename = "\(baseName)-\(counter).\(ext)"
            outputURL = directory.appendingPathComponent(outputFilename)
            counter += 1
        }

        return outputURL
    }

    /// 顯示儲存對話框
    private func showSavePanel(for videoInfo: VideoInfo) -> URL? {
        let panel = NSSavePanel()
        panel.message = "選擇輸出檔案位置"
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        // 建議的檔名
        let inputURL = videoInfo.filePath
        let baseFilename = inputURL.deletingPathExtension().lastPathComponent

        let suffix: String
        switch selectedMode {
        case .crf:
            suffix = "-crf\(crfValue)"
        case .targetSize:
            suffix = "-\(Int(targetSizeMB))mb"
        case .resolution:
            suffix = "-\(targetResolution.rawValue.replacingOccurrences(of: " ", with: ""))"
        }

        panel.nameFieldStringValue = "\(baseFilename)\(suffix).mp4"

        // 預設目錄為影片所在目錄的父目錄
        panel.directoryURL = inputURL.deletingLastPathComponent()

        return panel.runModal() == .OK ? panel.url : nil
    }

    /// 選擇輸出目錄
    func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "選擇輸出目錄"

        if panel.runModal() == .OK {
            customOutputDirectory = panel.url
            useCustomOutputDirectory = true
            log("已選擇輸出目錄：\(panel.url?.path ?? "")", level: .info)
        }
    }

    /// 開啟輸出資料夾
    func revealInFinder() {
        guard let outputURL = outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    // MARK: - Preview

    /// 生成預覽
    func generatePreview() async {
        guard let videoInfo = videoInfo else { return }

        // 生成預覽暫存檔案
        let previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("preview-\(UUID().uuidString).mp4")

        do {
            let stream = await ffmpegService.compress(
                videoInfo: videoInfo,
                settings: currentSettings,
                outputURL: previewURL,
                isPreview: true
            )

            // 等待預覽完成
            for try await _ in stream {
                // 可以追蹤預覽進度，但這裡簡化處理
            }

            // 預覽完成，開啟檔案
            NSWorkspace.shared.open(previewURL)

        } catch {
            appState = .error("預覽失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - Validation

    /// 驗證設定
    func validateSettings() -> String? {
        switch selectedMode {
        case .crf:
            if crfValue < 18 || crfValue > 30 {
                return "CRF 值必須在 18-30 之間"
            }
            if crfValue < 20 {
                return "警告：CRF 值過低可能導致檔案非常大"
            }

        case .targetSize:
            if targetSizeMB < 1 {
                return "目標大小必須大於 1 MB"
            }
            if let videoInfo = videoInfo {
                let ratio = (targetSizeMB * 1024 * 1024) / Double(videoInfo.fileSize)
                if ratio < 0.1 {
                    return "警告：目標大小過小，畫質可能嚴重下降"
                }
            }

        case .resolution:
            if let videoInfo = videoInfo,
               targetResolution.height > videoInfo.height {
                return "警告：目標解析度高於原始解析度，可能不會改善畫質"
            }
        }

        return nil
    }

    // MARK: - Logging

    /// 記錄日誌
    func log(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        logs.append(entry)

        // 同時輸出到 Console
        let logMessage = entry.fullText
        switch level {
        case .info:
            os_log("%{public}@", log: .default, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: .default, type: .default, logMessage)
        case .error:
            os_log("%{public}@", log: .default, type: .error, logMessage)
        case .debug:
            os_log("%{public}@", log: .default, type: .debug, logMessage)
        }

        // 限制 log 數量（保留最近 100 條）
        if logs.count > 100 {
            logs.removeFirst(logs.count - 100)
        }
    }

    /// 複製所有日誌
    func copyAllLogs() {
        let allLogs = logs.map { $0.fullText }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(allLogs, forType: .string)
        log("已複製所有日誌到剪貼簿", level: .info)
    }

    /// 清除日誌
    func clearLogs() {
        logs.removeAll()
        log("日誌已清除", level: .info)
    }
}
