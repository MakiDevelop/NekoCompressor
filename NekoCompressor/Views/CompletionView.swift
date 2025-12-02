//
//  CompletionView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

/// 壓縮完成視圖
struct CompletionView: View {
    let outputURL: URL
    let onReset: () -> Void
    let onReveal: () -> Void

    @State private var isAnimating = false
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 24) {
            // 成功圖示
            ZStack {
                // 外層光環
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )

                // 內層圓圈
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.2),
                                Color.teal.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // 成功圖示
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(ModernColors.successGradient)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isAnimating)
            }

            VStack(spacing: 12) {
                Text("壓縮完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text("您的影片已成功壓縮")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            // 檔案資訊卡片
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "doc.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("輸出檔案")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Text(outputURL.lastPathComponent)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Divider()

                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    Text(outputURL.deletingLastPathComponent().path)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )

            // 操作按鈕
            HStack(spacing: 12) {
                // 在 Finder 中顯示
                Button(action: onReveal) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.gearshape")
                        Text("在 Finder 中顯示")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
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

                // 壓縮新影片
                Button(action: onReset) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("壓縮新影片")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ModernColors.primaryGradient)
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.teal.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .green.opacity(0.2), radius: 30, x: 0, y: 15)
        )
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}
