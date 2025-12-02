//
//  CompressionMode.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// 壓縮模式
enum CompressionMode: String, CaseIterable, Identifiable {
    case crf = "CRF模式"
    case targetSize = "目標大小"
    case resolution = "解析度轉換"

    var id: String { rawValue }

    /// 模式描述
    var description: String {
        switch self {
        case .crf:
            return "使用 CRF 值控制畫質（18-30），數值越低畫質越好"
        case .targetSize:
            return "指定目標檔案大小，系統自動計算所需碼率"
        case .resolution:
            return "轉換影片解析度，同時可調整 FPS 與音訊參數"
        }
    }
}

/// 影片編碼器
enum VideoCodec: String, CaseIterable, Identifiable {
    case h264 = "H.264"
    case h265 = "H.265"

    var id: String { rawValue }

    /// ffmpeg 編碼器名稱
    var ffmpegName: String {
        switch self {
        case .h264:
            return "libx264"
        case .h265:
            return "libx265"
        }
    }
}

/// 編碼預設
enum EncodingPreset: String, CaseIterable, Identifiable {
    case ultrafast = "ultrafast"
    case superfast = "superfast"
    case veryfast = "veryfast"
    case faster = "faster"
    case fast = "fast"
    case medium = "medium"
    case slow = "slow"
    case slower = "slower"
    case veryslow = "veryslow"

    var id: String { rawValue }

    /// 預設描述
    var description: String {
        switch self {
        case .ultrafast, .superfast, .veryfast:
            return "快速編碼，檔案較大"
        case .faster, .fast, .medium:
            return "平衡速度與檔案大小"
        case .slow, .slower, .veryslow:
            return "慢速編碼，檔案較小"
        }
    }
}

/// 解析度預設
enum ResolutionPreset: String, CaseIterable, Identifiable {
    case p2160 = "2160p (4K)"
    case p1440 = "1440p (2K)"
    case p1080 = "1080p (Full HD)"
    case p720 = "720p (HD)"
    case p480 = "480p"
    case p360 = "360p"

    var id: String { rawValue }

    /// 解析度高度
    var height: Int {
        switch self {
        case .p2160: return 2160
        case .p1440: return 1440
        case .p1080: return 1080
        case .p720: return 720
        case .p480: return 480
        case .p360: return 360
        }
    }

    /// 解析度寬度（16:9 比例）
    var width: Int {
        height * 16 / 9
    }
}
