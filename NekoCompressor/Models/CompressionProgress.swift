//
//  CompressionProgress.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// 壓縮進度資訊
struct CompressionProgress {
    /// 當前處理的 frame
    var currentFrame: Int

    /// 總 frame 數
    var totalFrames: Int

    /// 當前處理時間（秒）
    var currentTime: Double

    /// 總時長（秒）
    var totalDuration: Double

    /// 當前 FPS
    var fps: Double

    /// 當前碼率
    var bitrate: String

    /// 進度百分比（0.0 - 1.0）
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(currentTime / totalDuration, 1.0)
    }

    /// 進度百分比字串
    var progressPercentage: String {
        String(format: "%.1f%%", progress * 100)
    }

    /// 預估剩餘時間（秒）
    var estimatedTimeRemaining: Double? {
        guard fps > 0, totalFrames > 0, currentFrame > 0 else { return nil }
        let remainingFrames = totalFrames - currentFrame
        return Double(remainingFrames) / fps
    }

    /// 格式化的預估剩餘時間
    var estimatedTimeRemainingFormatted: String {
        guard let remaining = estimatedTimeRemaining else {
            return "計算中..."
        }

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60

        if minutes > 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "約 %d 小時 %d 分鐘", hours, mins)
        } else if minutes > 0 {
            return String(format: "約 %d 分 %d 秒", minutes, seconds)
        } else {
            return String(format: "約 %d 秒", seconds)
        }
    }

    /// 當前時間格式化 (MM:SS)
    var currentTimeFormatted: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 總時長格式化 (MM:SS)
    var totalDurationFormatted: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// 壓縮結果
enum CompressionResult {
    case success(outputURL: URL, fileSize: Int64)
    case failure(error: CompressionError)
    case cancelled
}

/// 壓縮錯誤
enum CompressionError: LocalizedError {
    case invalidInput(String)
    case ffmpegNotFound
    case encodingFailed(String)
    case cancelled
    case outputPathNotSet
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "無效的輸入：\(message)"
        case .ffmpegNotFound:
            return "找不到 ffmpeg 執行檔"
        case .encodingFailed(let message):
            return "編碼失敗：\(message)"
        case .cancelled:
            return "壓縮已取消"
        case .outputPathNotSet:
            return "未設定輸出路徑"
        case .unknown(let message):
            return "未知錯誤：\(message)"
        }
    }
}
