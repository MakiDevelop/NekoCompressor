//
//  LogView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

/// 日誌視圖
struct LogView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedLog: LogEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("日誌", systemImage: "text.justifyleft")
                    .font(.headline)

                Spacer()

                Button(action: {
                    viewModel.copyAllLogs()
                }) {
                    Label("複製全部", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    viewModel.clearLogs()
                }) {
                    Label("清除", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }

            Divider()

            if viewModel.logs.isEmpty {
                Text("暫無日誌")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.logs) { log in
                                LogEntryRow(log: log, isSelected: selectedLog?.id == log.id)
                                    .id(log.id)
                                    .onTapGesture {
                                        selectedLog = log
                                        // 複製單一日誌
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(log.fullText, forType: .string)
                                    }
                            }
                        }
                        .onChange(of: viewModel.logs.count) {
                            // 自動滾動到最新日誌
                            if let lastLog = viewModel.logs.last {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding()
        .glassCard(cornerRadius: 16)
    }
}

/// 日誌條目行
struct LogEntryRow: View {
    let log: LogEntry
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 時間戳記
            Text(log.formattedTimestamp)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            // 等級標籤
            Text(log.level.rawValue)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(logLevelColor)
                .frame(width: 60, alignment: .leading)

            // 訊息
            Text(log.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)

            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }

    private var logLevelColor: Color {
        switch log.level {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .debug:
            return .gray
        }
    }
}
