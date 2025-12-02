# NekoCompressor PRD（完整版）

## 1. 專案背景
NekoCompressor 是一款 macOS 專用的影片壓縮工具，目標是讓一般使用者在不理解 ffmpeg 指令的狀況下，也能直觀地完成影片壓縮。專案專注於提供清楚的參數標示、視覺化 UI 流程與實用的壓縮模式。

## 2. 目標使用者
- 需要快速壓縮影片的人（上傳社群、傳檔案、剪輯前降碼率）
- 不想使用終端機、無法記住 ffmpeg 參數的使用者
- 內容創作者、學生、工程師、社群經營者

## 3. 產品目標
1. 提供安全、快速、穩定的 macOS 影片壓縮流程。
2. 讓使用者理解壓縮參數的效果（CRF、碼率、解析度）。
3. 進行壓縮前、自動分析影片資訊（碼率、解析度、長度、大小）。
4. 輕鬆選擇壓縮模式：CRF / 目標大小 / 解析度轉換。

## 4. 核心功能需求

### 4.1 影片匯入（Drag & Drop）
- 支援格式：MP4 / MOV / M4V
- 自動解析以下資訊：
  - 時長
  - 影像寬高
  - FPS
  - 碼率
  - 檔案大小

### 4.2 壓縮模式
#### A. CRF 模式
- 參數：
  - CRF 值（18–30）
  - 編碼器：H.264 / H.265
  - Preset：ultrafast ~ veryslow
- 系統顯示「畫質等級」標籤。

#### B. 固定檔案大小模式
- 使用者輸入目標大小（如：50MB）
- 系統依影片長度自動計算所需 bitrate
- 介面顯示「預估畫質」。

#### C. 解析度轉換模式
- 解析度選擇：1080p / 720p / 480p / 360p
- 可設定 FPS 與音訊參數

### 4.3 壓縮預覽模式
- 提供前 3 秒的壓縮 preview
- Before/After 切換比較
- 壓縮參數取自當前設定，但僅作用於前 3 秒。

### 4.4 壓縮流程控制
- 顯示:
  - 當前 frame
  - FPS
  - Time
  - 預估完成時間
- 若 ffmpeg 錯誤要以 Alert 呈現

### 4.5 產出設定
- 輸出到原始目錄或使用者指定路徑
- 檔名格式：
  - filename-compressed.mp4
  - filename-crf23.mp4

## 5. 技術架構

### 5.1 App 架構
- Swift + SwiftUI
- MVVM + AsyncProcess（啟動 ffmpeg 子程序）
- ffprobe 用於讀取 metadata
- ffmpeg binary 內嵌 /Resources/ffmpeg

### 5.2 ffmpeg Integration
- 透過 Process()
- 利用 Pipe() 解析 stderr 回傳進度

### 5.3 macOS Sandbox
- 需允許：
  - 檔案讀寫權限
  - 外部 binary 執行（使用 App Sandbox Exceptions）

## 6. 使用者流程

1. 開啟 App
2. 拖入影片
3. 選擇壓縮模式
4. 查看預估檔案大小
5. 點擊「開始壓縮」
6. 看到進度條更新
7. 壓縮完成後彈出 Finder

## 7. 邊界情境

- 影片過短（<1 秒）→ 不提供 Preview
- 破損影片 → 顯示錯誤
- 使用者輸入低於合理數值的 CRF → 警告
- 使用者輸入極端目標大小（如 1MB）→ 提醒畫質會嚴重破壞

## 8. 未來擴充
- 批次壓縮
- Metadata 保留選項
- AI 建議最佳壓縮參數
- iOS / iPadOS 版本
