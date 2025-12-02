//
//  VideoInfo.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// 影片資訊模型
struct VideoInfo: Codable {
    /// 影片檔案路徑
    let filePath: URL

    /// 檔案大小（bytes）
    let fileSize: Int64

    /// 影片時長（秒）
    let duration: Double

    /// 影片寬度
    let width: Int

    /// 影片高度
    let height: Int

    /// 影片 FPS
    let fps: Double

    /// 影片碼率（bits per second）
    let bitrate: Int64

    /// 影片格式
    let format: String

    /// 音訊編碼
    let audioCodec: String?

    /// 影片編碼
    let videoCodec: String

    /// 格式化的檔案大小字串
    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// 格式化的時長字串 (HH:MM:SS)
    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// 格式化的解析度字串
    var resolutionFormatted: String {
        "\(width)×\(height)"
    }

    /// 格式化的碼率字串
    var bitrateFormatted: String {
        let kbps = Double(bitrate) / 1000
        if kbps > 1000 {
            return String(format: "%.2f Mbps", kbps / 1000)
        } else {
            return String(format: "%.0f kbps", kbps)
        }
    }
}
