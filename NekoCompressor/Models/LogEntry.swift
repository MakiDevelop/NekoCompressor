//
//  LogEntry.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// 日誌等級
enum LogLevel: String {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case debug = "DEBUG"
}

/// 日誌條目
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String

    /// 格式化的時間戳記
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    /// 完整的日誌字串（用於複製）
    var fullText: String {
        "[\(formattedTimestamp)] [\(level.rawValue)] \(message)"
    }
}
