//
//  CompressionProgressView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

/// 現代化壓縮進度視圖
struct CompressionProgressView: View {
    let progress: CompressionProgress
    let onCancel: () -> Void

    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // 圓形進度指示器
            ZStack {
                // 背景圓圈
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.1),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 200, height: 200)

                // 進度圓圈
                Circle()
                    .trim(from: 0, to: progress.progress)
                    .stroke(
                        ModernColors.primaryGradient,
                        style: StrokeStyle(
                            lineWidth: 20,
                            lineCap: .round
                        )
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress.progress)

                // 發光效果
                Circle()
                    .trim(from: 0, to: progress.progress)
                    .stroke(
                        Color.purple.opacity(0.5),
                        style: StrokeStyle(
                            lineWidth: 25,
                            lineCap: .round
                        )
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 10)
                    .animation(.easeInOut(duration: 0.3), value: progress.progress)

                // 中心內容
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundStyle(ModernColors.primaryGradient)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false),
                            value: rotationAngle
                        )

                    Text(progress.progressPercentage)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("處理中")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            // 詳細資訊卡片
            VStack(spacing: 12) {
                // 時間資訊
                HStack(spacing: 12) {
                    ProgressStatCard(
                        icon: "clock.fill",
                        title: "已處理",
                        value: progress.currentTimeFormatted,
                        color: .blue
                    )

                    ProgressStatCard(
                        icon: "hourglass",
                        title: "剩餘",
                        value: progress.estimatedTimeRemainingFormatted,
                        color: .orange
                    )
                }

                // Frame 資訊
                HStack(spacing: 12) {
                    ProgressStatCard(
                        icon: "film.fill",
                        title: "Frames",
                        value: "\(progress.currentFrame)/\(progress.totalFrames)",
                        color: .purple
                    )

                    ProgressStatCard(
                        icon: "speedometer",
                        title: "FPS",
                        value: String(format: "%.1f", progress.fps),
                        color: .green
                    )
                }

                // 碼率
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("當前碼率")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(progress.bitrate)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Spacer()
                }
                .padding()
                .glassCard(cornerRadius: 12)
            }

            // 取消按鈕
            Button(action: onCancel) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                    Text("取消壓縮")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.8),
                                    Color.orange.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
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
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
        )
        .onAppear {
            withAnimation {
                rotationAngle = 360
            }
        }
    }
}

/// 進度統計卡片
struct ProgressStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
}
