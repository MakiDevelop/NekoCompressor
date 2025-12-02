//
//  ContentView.swift
//  NekoCompressor
//
//  Created by 千葉牧人 on 2025/12/1.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        ZStack {
            // 更亮的背景漸層
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.92, blue: 0.96),
                    Color(red: 0.88, green: 0.90, blue: 0.98),
                    Color(red: 0.85, green: 0.88, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 標題列
                HeaderView(
                    appState: viewModel.appState,
                    videoTitle: viewModel.videoInfo?.filePath.lastPathComponent
                )

                // 主內容區
                ScrollView {
                    VStack(spacing: 24) {
                        if let videoInfo = viewModel.videoInfo {
                            if case .idle = viewModel.appState {
                                // 匯入前不顯示摘要
                            } else {
                                contextSummary(videoInfo: videoInfo)
                            }
                        }

                        switch viewModel.appState {
                        case .idle:
                            idleView

                        case .analyzing:
                            analyzingView

                        case .ready:
                            readyView

                        case .compressing:
                            compressingView

                        case .completed:
                            completedView

                        case .error(let message):
                            errorView(message: message)
                        }
                    }
                    .padding(24)
                }

                // 底部操作列
                bottomBar
            }
        }
        .frame(minWidth: 800, minHeight: 700)
    }

    // MARK: - Idle View

    private var idleView: some View {
        DropZoneView { url in
            Task {
                await viewModel.importVideo(url: url)
            }
        }
        .frame(height: 400)
        .padding(.top, 20)
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("正在分析影片...")
                .font(.headline)
        }
        .frame(height: 300)
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: 20) {
            if let videoInfo = viewModel.videoInfo {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        VideoInfoView(videoInfo: videoInfo) {
                            viewModel.resetVideo()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 18) {
                            CompressionSettingsView(viewModel: viewModel)
                            OutputSettingsView(viewModel: viewModel)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: 18) {
                        VideoInfoView(videoInfo: videoInfo) {
                            viewModel.resetVideo()
                        }

                        CompressionSettingsView(viewModel: viewModel)
                        OutputSettingsView(viewModel: viewModel)
                    }
                }

                // 日誌視圖
                if !viewModel.logs.isEmpty {
                    LogView(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Compressing View

    private var compressingView: some View {
        VStack(spacing: 20) {
            if let progress = viewModel.compressionProgress {
                CompressionProgressView(progress: progress) {
                    Task {
                        await viewModel.cancelCompression()
                    }
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("正在準備壓縮...")
                        .font(.headline)
                }
            }

            // 壓縮時也顯示日誌
            if !viewModel.logs.isEmpty {
                LogView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 20) {
            if let outputURL = viewModel.outputURL {
                CompletionView(
                    outputURL: outputURL,
                    onReset: {
                        viewModel.resetVideo()
                    },
                    onReveal: {
                        viewModel.revealInFinder()
                    }
                )
            }
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("發生錯誤")
                .font(.title2)
                .fontWeight(.bold)

            // 錯誤訊息（可複製）
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                }) {
                    Label("複製錯誤訊息", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Button(action: {
                viewModel.resetVideo()
            }) {
                Text("重試")
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)

            // 顯示完整日誌
            if !viewModel.logs.isEmpty {
                LogView(viewModel: viewModel)
            }
        }
        .padding()
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: -5)

            HStack(spacing: 16) {
                // 左側：預覽按鈕
                if viewModel.canStartCompression {
                    Button(action: {
                        Task {
                            await viewModel.generatePreview()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                            Text("預覽 (前3秒)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.8),
                                            Color.cyan.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.secondary)
                        Text("匯入影片後即可預覽或開始壓縮")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }

                Spacer()

                // 右側：開始壓縮按鈕
                if viewModel.canStartCompression {
                    Button(action: {
                        Task {
                            await viewModel.startCompression()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.headline)
                            Text("開始壓縮")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(ModernColors.primaryGradient)
                                .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.validateSettings()?.contains("必須") ?? false)
                    .opacity((viewModel.validateSettings()?.contains("必須") ?? false) ? 0.5 : 1.0)
                }
            }
            .padding()
        }
        .frame(height: 80)
    }
}

// MARK: - Header View

struct HeaderView: View {
    let appState: AppState
    let videoTitle: String?
    @State private var isAnimating = false

    private var status: (text: String, color: Color, icon: String) {
        switch appState {
        case .idle:
            return ("等待匯入", .gray, "tray")
        case .analyzing:
            return ("解析中", .blue, "waveform.path.ecg")
        case .ready:
            return ("設定就緒", .green, "checkmark.circle")
        case .compressing:
            return ("壓縮中", .purple, "sparkles")
        case .completed:
            return ("完成", .green, "party.popper")
        case .error:
            return ("需要注意", .orange, "exclamationmark.triangle")
        }
    }

    private var subtitle: String {
        if let videoTitle {
            return "目前檔案：\(videoTitle)"
        }

        switch appState {
        case .idle:
            return "拖放影片即可開始壓縮"
        case .analyzing:
            return "正在解析影片資訊"
        case .ready:
            return "調整設定後開始壓縮"
        case .compressing:
            return "請保持應用程式開啟"
        case .completed:
            return "檔案已輸出，可以再次壓縮"
        case .error:
            return "請檢查錯誤訊息或重新選擇"
        }
    }

    var body: some View {
        ZStack {
            // 漸層背景
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.5),
                            Color.blue.opacity(0.5),
                            Color.cyan.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 玻璃效果
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.9)

            HStack(spacing: 16) {
                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.blue.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Image(systemName: "video.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NekoCompressor")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // 狀態指示器
                HStack(spacing: 8) {
                    Image(systemName: status.icon)
                        .font(.caption)
                        .foregroundColor(.white)

                    Text(status.text)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(status.color.opacity(0.9))
                        .shadow(color: status.color.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .padding()
        }
        .frame(height: 70)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Context Summary

private extension ContentView {
    func contextSummary(videoInfo: VideoInfo) -> some View {
        let outputPath = viewModel.useCustomOutputDirectory
            ? (viewModel.customOutputDirectory?.lastPathComponent ?? "自訂路徑")
            : "另存/暫存目錄"

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                SummaryChip(
                    icon: "film.stack",
                    title: "已匯入",
                    value: "\(videoInfo.resolutionFormatted) · \(videoInfo.durationFormatted)",
                    detail: videoInfo.filePath.lastPathComponent,
                    color: .blue
                )

                SummaryChip(
                    icon: "slider.horizontal.3",
                    title: "模式",
                    value: viewModel.selectedMode.rawValue,
                    detail: viewModel.selectedCodec.rawValue.uppercased(),
                    color: .purple
                )

                SummaryChip(
                    icon: "folder",
                    title: "輸出位置",
                    value: outputPath,
                    detail: viewModel.useCustomFilename && !viewModel.customFilename.isEmpty
                        ? viewModel.customFilename + ".mp4"
                        : "將自動避免覆寫",
                    color: .green
                )
            }

            VStack(spacing: 12) {
                SummaryChip(
                    icon: "film.stack",
                    title: "已匯入",
                    value: "\(videoInfo.resolutionFormatted) · \(videoInfo.durationFormatted)",
                    detail: videoInfo.filePath.lastPathComponent,
                    color: .blue
                )

                SummaryChip(
                    icon: "slider.horizontal.3",
                    title: "模式",
                    value: viewModel.selectedMode.rawValue,
                    detail: viewModel.selectedCodec.rawValue.uppercased(),
                    color: .purple
                )

                SummaryChip(
                    icon: "folder",
                    title: "輸出位置",
                    value: outputPath,
                    detail: viewModel.useCustomFilename && !viewModel.customFilename.isEmpty
                        ? viewModel.customFilename + ".mp4"
                        : "將自動避免覆寫",
                    color: .green
                )
            }
        }
    }
}

private struct SummaryChip: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 14)
    }
