# AGENTS.md（工程師版指示）

## 1. 專案目標
為 macOS 開發一款 SwiftUI App「NekoCompressor」，整合 ffmpeg，提供影片匯入、資訊解析、三種壓縮模式、預覽與輸出功能。

## 2. 資料夾結構
```
NekoCompressor/
 ├── App/
 ├── Views/
 ├── ViewModels/
 ├── Models/
 ├── Services/
 │    ├── FFmpegService.swift
 │    ├── ProbeService.swift
 ├── Resources/
 │    ├── ffmpeg
 │    ├── ffprobe
 ├── Utils/
 └── Generated/
```

## 3. 任務分解（工程師導向）

### A. 實作影片匯入
- 建立 Drag & Drop 區域
- 實作 ProbeService 呼叫 ffprobe
- 將結果解碼成 Model：VideoInfo

### B. 壓縮模式邏輯
- 實作 CRFModel、SizeTargetModel、ResolutionModel
- 將使用者選項組成 ffmpeg 指令

### C. ffmpeg 呼叫
- 使用 `Process()` 執行 ffmpeg binary
- 用 `Pipe()` 接 stderr
- 解析進度資訊：frame, time, bitrate…

### D. 預覽模式
- 以 `-t 3` 限制三秒
- 輸出暫存 preview.mp4

### E. 主壓縮流程
- `FFmpegService.compress(videoInfo, settings)`
- 回傳：
  - success
  - failed(errorMessage)
  - progress(frame, time)

### F. UI / UX 整合
- SwiftUI ViewModel 綁定進度
- ProgressView 實時更新
- 錯誤以 Alert 呈現

### G. 輸出邏輯
- 依設定寫入目錄
- 自動 rename 避免覆寫

## 4. 程式風格規範
- 使用 enum 管理 codec、preset、解析度
- 所有 ffmpeg 指令字串以 struct 生成
- 重要運算（bitrate 公式）須寫成可測試的 pure function

## 5. 必要外部工具
- ffmpeg 與 ffprobe 必須為 macOS arm64 靜態編譯版本
- 放置於 Resources 以便 sandbox 執行

## 6. 生成產物要求
- App 必須可由 Xcode 15 以上版本編譯
- Swift 5.9+
- macOS Deployment Target: 13.0+
```

# END
