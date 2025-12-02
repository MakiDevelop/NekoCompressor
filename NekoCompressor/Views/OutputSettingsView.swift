//
//  OutputSettingsView.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

/// 輸出設定視圖
struct OutputSettingsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("輸出設定")
                .font(.headline)

            Divider()

            // 輸出目錄
            VStack(alignment: .leading, spacing: 8) {
                Toggle("自訂輸出目錄", isOn: $viewModel.useCustomOutputDirectory)

                if viewModel.useCustomOutputDirectory {
                    HStack {
                        if let directory = viewModel.customOutputDirectory {
                            Text(directory.path)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("尚未選擇")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.selectOutputDirectory()
                        }) {
                            Label("選擇資料夾", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Divider()

            // 自訂檔名
            VStack(alignment: .leading, spacing: 8) {
                Toggle("自訂檔名", isOn: $viewModel.useCustomFilename)

                if viewModel.useCustomFilename {
                    HStack {
                        TextField("輸入檔名（不含副檔名）", text: $viewModel.customFilename)
                            .textFieldStyle(.roundedBorder)

                        Text(".mp4")
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading)
                }
            }

            Divider()

            // 其他選項
            VStack(alignment: .leading, spacing: 8) {
                Toggle("覆寫同名檔案", isOn: $viewModel.overwriteExisting)
                    .help("如果啟用，將直接覆寫已存在的同名檔案")

                Toggle("保留原始 Metadata", isOn: $viewModel.keepMetadata)
                    .help("保留影片的 metadata（如：拍攝時間、GPS 資訊等）")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
