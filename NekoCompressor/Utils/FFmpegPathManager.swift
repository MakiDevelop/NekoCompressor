//
//  FFmpegPathManager.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// 管理 ffmpeg 和 ffprobe 的路徑
enum FFmpegPathManager {
    /// 取得 ffmpeg 執行檔路徑
    static func ffmpegPath() -> URL? {
        // 優先從 Bundle Resources 取得
        if let bundlePath = Bundle.main.url(forResource: "ffmpeg", withExtension: nil) {
            return bundlePath
        }

        // 開發環境：從專案 Resources 資料夾取得
        let projectResourcesPath = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("NekoCompressor")
            .appendingPathComponent("Resources")
            .appendingPathComponent("ffmpeg")

        if FileManager.default.fileExists(atPath: projectResourcesPath.path) {
            return projectResourcesPath
        }

        // 系統路徑（開發/測試用）
        let systemPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in systemPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    /// 取得 ffprobe 執行檔路徑
    static func ffprobePath() -> URL? {
        // 優先從 Bundle Resources 取得
        if let bundlePath = Bundle.main.url(forResource: "ffprobe", withExtension: nil) {
            return bundlePath
        }

        // 開發環境：從專案 Resources 資料夾取得
        let projectResourcesPath = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("NekoCompressor")
            .appendingPathComponent("Resources")
            .appendingPathComponent("ffprobe")

        if FileManager.default.fileExists(atPath: projectResourcesPath.path) {
            return projectResourcesPath
        }

        // 系統路徑（開發/測試用）
        let systemPaths = [
            "/opt/homebrew/bin/ffprobe",
            "/usr/local/bin/ffprobe",
            "/usr/bin/ffprobe"
        ]

        for path in systemPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    /// 驗證 ffmpeg 和 ffprobe 是否可用
    static func validate() -> Bool {
        return ffmpegPath() != nil && ffprobePath() != nil
    }
}
