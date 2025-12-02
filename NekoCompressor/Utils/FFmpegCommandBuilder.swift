//
//  FFmpegCommandBuilder.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import Foundation

/// ffmpeg 命令建構器
struct FFmpegCommandBuilder {

    /// 建立壓縮命令參數
    /// - Parameters:
    ///   - inputURL: 輸入影片路徑
    ///   - outputURL: 輸出影片路徑
    ///   - settings: 壓縮設定
    ///   - videoInfo: 影片資訊
    ///   - isPreview: 是否為預覽模式（限制 3 秒）
    /// - Returns: ffmpeg 命令參數陣列
    static func buildArguments(
        inputURL: URL,
        outputURL: URL,
        settings: CompressionSettings,
        videoInfo: VideoInfo,
        isPreview: Bool = false
    ) -> [String] {
        var arguments: [String] = []

        // 覆寫輸出檔案
        arguments.append("-y")

        // 輸入檔案
        arguments.append("-i")
        arguments.append(inputURL.path)

        // 預覽模式：限制 3 秒
        if isPreview {
            arguments.append("-t")
            arguments.append("3")
        }

        // 根據壓縮模式建立參數
        switch settings.mode {
        case .crf:
            if let crfSettings = settings.crfSettings {
                arguments.append(contentsOf: buildCRFArguments(crfSettings, codec: settings.codec))
            }

        case .targetSize:
            if let targetSettings = settings.targetSizeSettings {
                arguments.append(contentsOf: buildTargetSizeArguments(
                    targetSettings,
                    codec: settings.codec,
                    videoInfo: videoInfo
                ))
            }

        case .resolution:
            if let resolutionSettings = settings.resolutionSettings {
                arguments.append(contentsOf: buildResolutionArguments(
                    resolutionSettings,
                    codec: settings.codec,
                    videoInfo: videoInfo
                ))
            }
        }

        // 輸出檔案
        arguments.append(outputURL.path)

        return arguments
    }

    /// 建立 CRF 模式參數
    private static func buildCRFArguments(_ settings: CRFSettings, codec: VideoCodec) -> [String] {
        var args: [String] = []

        // 影片編碼器
        args.append("-c:v")
        args.append(codec.ffmpegName)

        // CRF 值
        args.append("-crf")
        args.append("\(settings.crfValue)")

        // Preset
        args.append("-preset")
        args.append(settings.preset.rawValue)

        // 音訊編碼（copy 保持原始）
        args.append("-c:a")
        args.append("copy")

        return args
    }

    /// 建立目標大小模式參數
    private static func buildTargetSizeArguments(
        _ settings: TargetSizeSettings,
        codec: VideoCodec,
        videoInfo: VideoInfo
    ) -> [String] {
        var args: [String] = []

        // 影片編碼器
        args.append("-c:v")
        args.append(codec.ffmpegName)

        // 計算影片碼率
        let videoBitrate = settings.calculateVideoBitrate(duration: videoInfo.duration)
        args.append("-b:v")
        args.append("\(videoBitrate)k")

        // 音訊處理
        if settings.includeAudio {
            args.append("-c:a")
            args.append("aac")
            args.append("-b:a")
            args.append("\(settings.audioBitrate)k")
        } else {
            args.append("-an")
        }

        // 使用 2-pass 編碼以確保檔案大小準確（可選）
        // 這裡先使用 single pass，需要的話可以改成 2-pass

        return args
    }

    /// 建立解析度轉換模式參數
    private static func buildResolutionArguments(
        _ settings: ResolutionSettings,
        codec: VideoCodec,
        videoInfo: VideoInfo
    ) -> [String] {
        var args: [String] = []

        // 影片編碼器
        args.append("-c:v")
        args.append(codec.ffmpegName)

        // 解析度縮放
        if settings.maintainAspectRatio {
            // 保持長寬比，高度固定
            args.append("-vf")
            args.append("scale=-2:\(settings.targetResolution.height)")
        } else {
            // 固定解析度
            args.append("-vf")
            args.append("scale=\(settings.targetResolution.width):\(settings.targetResolution.height)")
        }

        // FPS
        if let targetFPS = settings.targetFPS {
            args.append("-r")
            args.append("\(targetFPS)")
        }

        // Preset
        args.append("-preset")
        args.append(settings.preset.rawValue)

        // 音訊編碼
        args.append("-c:a")
        args.append("aac")
        args.append("-b:a")
        args.append("\(settings.audioBitrate)k")

        return args
    }
}
