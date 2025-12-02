//
//  CompressionSettings.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// 壓縮設定
struct CompressionSettings {
    /// 壓縮模式
    let mode: CompressionMode

    /// 編碼器
    let codec: VideoCodec

    /// CRF 模式設定
    var crfSettings: CRFSettings?

    /// 目標大小模式設定
    var targetSizeSettings: TargetSizeSettings?

    /// 解析度轉換模式設定
    var resolutionSettings: ResolutionSettings?

    /// 輸出路徑
    var outputPath: URL?
}

/// CRF 模式設定
struct CRFSettings {
    /// CRF 值 (18-30)
    var crfValue: Int

    /// 編碼預設
    var preset: EncodingPreset

    /// 是否為有效的 CRF 值
    var isValid: Bool {
        crfValue >= 18 && crfValue <= 30
    }

    /// 畫質等級描述
    var qualityDescription: String {
        switch crfValue {
        case 18...20:
            return "極高畫質"
        case 21...23:
            return "高畫質"
        case 24...26:
            return "中等畫質"
        case 27...28:
            return "中低畫質"
        case 29...30:
            return "低畫質"
        default:
            return "無效值"
        }
    }

    /// 預設設定
    static var `default`: CRFSettings {
        CRFSettings(crfValue: 23, preset: .medium)
    }
}

/// 目標大小模式設定
struct TargetSizeSettings {
    /// 目標檔案大小（MB）
    var targetSizeMB: Double

    /// 是否包含音訊
    var includeAudio: Bool

    /// 音訊碼率（kbps）
    var audioBitrate: Int

    /// 計算所需的影片碼率（根據影片時長）
    func calculateVideoBitrate(duration: Double) -> Int {
        guard duration > 0 else { return 0 }

        // 目標大小轉換為 bits
        let targetSizeBits = targetSizeMB * 8 * 1024 * 1024

        // 扣除音訊大小
        let audioBits = includeAudio ? Double(audioBitrate * 1000) * duration : 0

        // 計算影片碼率 (kbps)
        let videoBitrate = (targetSizeBits - audioBits) / duration / 1000

        return max(Int(videoBitrate), 100) // 最低 100 kbps
    }

    /// 預估畫質
    func estimateQuality(for videoInfo: VideoInfo) -> String {
        let calculatedBitrate = calculateVideoBitrate(duration: videoInfo.duration)
        let originalBitrate = Int(videoInfo.bitrate / 1000)

        let ratio = Double(calculatedBitrate) / Double(originalBitrate)

        switch ratio {
        case 0.8...:
            return "畫質良好"
        case 0.5..<0.8:
            return "畫質中等"
        case 0.3..<0.5:
            return "畫質偏低"
        default:
            return "畫質嚴重下降"
        }
    }

    /// 預設設定
    static var `default`: TargetSizeSettings {
        TargetSizeSettings(targetSizeMB: 50, includeAudio: true, audioBitrate: 128)
    }
}

/// 解析度轉換模式設定
struct ResolutionSettings {
    /// 目標解析度
    var targetResolution: ResolutionPreset

    /// 目標 FPS（nil 表示保持原始）
    var targetFPS: Int?

    /// 編碼預設
    var preset: EncodingPreset

    /// 音訊碼率（kbps）
    var audioBitrate: Int

    /// 是否保持長寬比
    var maintainAspectRatio: Bool

    /// 預設設定
    static var `default`: ResolutionSettings {
        ResolutionSettings(
            targetResolution: .p1080,
            targetFPS: nil,
            preset: .medium,
            audioBitrate: 128,
            maintainAspectRatio: true
        )
    }
}
