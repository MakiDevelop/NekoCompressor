//
//  VideoInfoView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

/// 現代化影片資訊顯示視圖
struct VideoInfoView: View {
    let videoInfo: VideoInfo
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 標題列
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title)
                        .foregroundStyle(ModernColors.primaryGradient)

                    Text("影片資訊")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: onReset) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("重新選擇")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.orange,
                                        Color.red
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            // 檔案名稱卡片
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "doc.fill")
                        .font(.title3)
                        .foregroundStyle(ModernColors.primaryGradient)
                    Text("檔案名稱")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Text(videoInfo.filePath.lastPathComponent)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )

            // 資訊網格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // 檔案大小
                InfoCard(
                    icon: "internaldrive.fill",
                    title: "檔案大小",
                    value: videoInfo.fileSizeFormatted,
                    color: .blue
                )

                // 時長
                InfoCard(
                    icon: "clock.fill",
                    title: "時長",
                    value: videoInfo.durationFormatted,
                    color: .purple
                )

                // 解析度
                InfoCard(
                    icon: "viewfinder",
                    title: "解析度",
                    value: videoInfo.resolutionFormatted,
                    color: .indigo
                )

                // FPS
                InfoCard(
                    icon: "speedometer",
                    title: "FPS",
                    value: String(format: "%.0f", videoInfo.fps),
                    color: .green
                )

                // 碼率
                InfoCard(
                    icon: "waveform",
                    title: "碼率",
                    value: videoInfo.bitrateFormatted,
                    color: .orange
                )

                // 影片編碼
                InfoCard(
                    icon: "film.fill",
                    title: "影片編碼",
                    value: videoInfo.videoCodec.uppercased(),
                    color: .pink
                )
            }

            // 音訊和格式資訊
            HStack(spacing: 12) {
                if let audioCodec = videoInfo.audioCodec {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("音訊編碼")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(audioCodec.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 12)
                }

                HStack(spacing: 8) {
                    Image(systemName: "cube.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mint, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("格式")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(videoInfo.format.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

/// 資訊卡片
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
}
