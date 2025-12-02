//
//  DropZoneView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI
import UniformTypeIdentifiers

/// 現代化拖放區域視圖
struct DropZoneView: View {
    let onDrop: (URL) -> Void
    @State private var isTargeted = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 白色背景層
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            // 背景動畫漸層
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: isTargeted ? [
                            Color.purple.opacity(0.15),
                            Color.blue.opacity(0.15)
                        ] : [
                            Color.purple.opacity(0.03),
                            Color.blue.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .animation(.easeInOut(duration: 0.3), value: isTargeted)

            // 虛線邊框
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: isTargeted ? [
                            Color.purple,
                            Color.blue
                        ] : [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 3,
                        dash: isTargeted ? [20, 0] : [20, 10]
                    )
                )
                .animation(.easeInOut(duration: 0.3), value: isTargeted)

            // 內容
            VStack(spacing: 24) {
                // 主圖示
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.2),
                                    Color.blue.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Image(systemName: isTargeted ? "video.fill.badge.checkmark" : "video.badge.plus")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isTargeted ? [
                                    Color.green,
                                    Color.blue
                                ] : [
                                    Color.purple,
                                    Color.blue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: isTargeted)
                }

                VStack(spacing: 12) {
                    Text(isTargeted ? "放開以開始分析" : "拖放影片檔案")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    HStack(spacing: 10) {
                        ForEach(["MP4", "MOV", "M4V"], id: \.self) { format in
                            Text(format)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.purple,
                                                    Color.blue
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                }

                // 提示文字
                VStack(spacing: 8) {
                    Text("或點擊選擇檔案")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Button(action: {
                        selectFile()
                    }) {
                        Text("瀏覽...")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(ModernColors.primaryGradient)
                                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                guard let data = data as? Data,
                      let path = String(data: data, encoding: .utf8),
                      let url = URL(string: path) else {
                    return
                }

                // 驗證檔案格式
                let allowedExtensions = ["mp4", "mov", "m4v"]
                let fileExtension = url.pathExtension.lowercased()

                if allowedExtensions.contains(fileExtension) {
                    DispatchQueue.main.async {
                        onDrop(url)
                    }
                }
            }

            return true
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]
        panel.message = "選擇要壓縮的影片檔案"

        if panel.runModal() == .OK, let url = panel.url {
            onDrop(url)
        }
    }
}
