# NekoCompressor

NekoCompressor 是一款專為 macOS 打造的輕量級影片壓縮工具。  
設計理念簡單直接：拖影片、選參數、一鍵壓縮。  
不需要記 ffmpeg 指令、不需要用終端機。

---

## ✨ 核心功能

### 🎬 影片拖曳匯入
- 支援 MP4 / MOV / M4V  
- 自動解析：解析度、FPS、時長、碼率、檔案大小

### 🛠 三種壓縮模式
1. **CRF 模式**（畫質優先）  
2. **目標檔案大小模式**（輸入 50MB 之類即可）  
3. **解析度轉換模式**（1080p → 720p 等）

### 👀 壓縮預覽
- 只壓 3 秒，立即看 before/after 差異  
- 測試參數不用花時間

### 📊 即時進度條
- 顯示時間、frame、FPS、預估剩餘時間

### 📁 彈性輸出
- 自動命名檔案  
- 可選擇輸出位置  
- 避免覆蓋原檔

---

## 🧩 技術架構概述

- **Swift + SwiftUI**  
- 使用 macOS `Process()` 呼叫內嵌 **ffmpeg / ffprobe**  
- Pipe stderr → 解析進度  
- MVVM 架構  
- 支援 macOS 13+  

---

## 🚀 未來規劃
- 批次壓縮  
- Metadata 選項  
- 智能參數建議  
- 自訂 Presets  
- iOS / iPadOS 版本  

---

## 🤝 貢獻
歡迎 issue / PR，一起把 NekoCompressor 打磨成最順手的 macOS 壓片工具。

---

## 🐾 關於貓
圖示中可見虎斑貓以貓掌壓住影片，象徵「壓縮」。  
牠是本專案的精神領袖，沒有任何勞動契約問題。

