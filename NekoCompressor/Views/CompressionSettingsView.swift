//
//  CompressionSettingsView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

/// 壓縮設定視圖
struct CompressionSettingsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("壓縮設定", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .labelStyle(.titleAndIcon)
                Spacer()
                Text(viewModel.selectedCodec.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
            }

            Divider()

            // 壓縮模式選擇
            Picker("壓縮模式", selection: $viewModel.selectedMode) {
                ForEach(CompressionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(viewModel.selectedMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            // 編碼器選擇
            HStack {
                Text("編碼器")
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $viewModel.selectedCodec) {
                    ForEach(VideoCodec.allCases) { codec in
                        Text(codec.rawValue).tag(codec)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            Divider()

            // 根據模式顯示不同設定
            switch viewModel.selectedMode {
            case .crf:
                CRFSettingsView(
                    crfValue: $viewModel.crfValue,
                    preset: $viewModel.crfPreset
                )

            case .targetSize:
                TargetSizeSettingsView(
                    targetSizeMB: $viewModel.targetSizeMB,
                    includeAudio: $viewModel.includeAudio,
                    audioBitrate: $viewModel.audioBitrate,
                    videoInfo: viewModel.videoInfo
                )

            case .resolution:
                ResolutionSettingsView(
                    targetResolution: $viewModel.targetResolution,
                    targetFPS: $viewModel.targetFPS,
                    preset: $viewModel.resolutionPreset,
                    audioBitrate: $viewModel.audioBitrate,
                    maintainAspectRatio: $viewModel.maintainAspectRatio
                )
            }

            // 驗證警告
            if let warning = viewModel.validateSettings() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - CRF Settings

struct CRFSettingsView: View {
    @Binding var crfValue: Int
    @Binding var preset: EncodingPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CRF 值")
                    .frame(width: 80, alignment: .leading)

                Slider(value: Binding(
                    get: { Double(crfValue) },
                    set: { crfValue = Int($0) }
                ), in: 18...30, step: 1)

                Text("\(crfValue)")
                    .frame(width: 30)
                    .fontWeight(.bold)

                Text(CRFSettings(crfValue: crfValue, preset: preset).qualityDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("編碼速度")
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $preset) {
                    ForEach(EncodingPreset.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .frame(maxWidth: 200)
            }

            Text(preset.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Target Size Settings

struct TargetSizeSettingsView: View {
    @Binding var targetSizeMB: Double
    @Binding var includeAudio: Bool
    @Binding var audioBitrate: Int
    let videoInfo: VideoInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("目標大小")
                    .frame(width: 80, alignment: .leading)

                TextField("MB", value: $targetSizeMB, format: .number)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)

                Text("MB")

                if let videoInfo = videoInfo {
                    let settings = TargetSizeSettings(
                        targetSizeMB: targetSizeMB,
                        includeAudio: includeAudio,
                        audioBitrate: audioBitrate
                    )
                    Text("(\(settings.estimateQuality(for: videoInfo)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle("包含音訊", isOn: $includeAudio)

            if includeAudio {
                HStack {
                    Text("音訊碼率")
                        .frame(width: 80, alignment: .leading)

                    Picker("", selection: $audioBitrate) {
                        Text("96 kbps").tag(96)
                        Text("128 kbps").tag(128)
                        Text("192 kbps").tag(192)
                        Text("256 kbps").tag(256)
                    }
                    .frame(maxWidth: 200)
                }
            }

            if let videoInfo = videoInfo {
                let estimatedBitrate = TargetSizeSettings(
                    targetSizeMB: targetSizeMB,
                    includeAudio: includeAudio,
                    audioBitrate: audioBitrate
                ).calculateVideoBitrate(duration: videoInfo.duration)

                Text("預估影片碼率：\(estimatedBitrate) kbps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Resolution Settings

struct ResolutionSettingsView: View {
    @Binding var targetResolution: ResolutionPreset
    @Binding var targetFPS: Int?
    @Binding var preset: EncodingPreset
    @Binding var audioBitrate: Int
    @Binding var maintainAspectRatio: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("解析度")
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $targetResolution) {
                    ForEach(ResolutionPreset.allCases) { res in
                        Text(res.rawValue).tag(res)
                    }
                }
                .frame(maxWidth: 200)
            }

            Toggle("保持長寬比", isOn: $maintainAspectRatio)

            HStack {
                Text("FPS")
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $targetFPS) {
                    Text("保持原始").tag(nil as Int?)
                    Text("24").tag(24 as Int?)
                    Text("30").tag(30 as Int?)
                    Text("60").tag(60 as Int?)
                }
                .frame(maxWidth: 200)
            }

            HStack {
                Text("編碼速度")
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $preset) {
                    ForEach(EncodingPreset.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .frame(maxWidth: 200)
            }

            HStack {
                Text("音訊碼率")
                    .frame(width: 80, alignment: .leading)

                Picker("", selection: $audioBitrate) {
                    Text("96 kbps").tag(96)
                    Text("128 kbps").tag(128)
                    Text("192 kbps").tag(192)
                    Text("256 kbps").tag(256)
                }
                .frame(maxWidth: 200)
            }
        }
    }
}
