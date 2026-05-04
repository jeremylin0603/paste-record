# PasteRecord

macOS 上的剪貼簿錄製 / 播放小工具。一次錄好 N 筆複製內容，切到目標視窗連按 Cmd+V，就能依序貼上，不用再來回切換視窗複製貼上。

## 使用情境

如果你需要把 A 視窗中 20 個關鍵字逐一複製到 B 視窗的不同欄位，傳統做法是「複製→切視窗→貼上→切回→複製下一個」重複 20 次。PasteRecord 把這個流程拆成兩階段：

1. 在 A 視窗一次錄好 20 筆複製內容
2. 切到 B 視窗連按 20 次 Cmd+V，依序自動貼上每一筆

## 操作流程

1. 按 **⌘⇧R** 進入「錄製模式」（選單列圖示變紅，浮動小視窗會出現）
2. 在 A 視窗依序選取 + Cmd+C 你要的每一個關鍵字，小視窗即時顯示已錄製的內容
3. 按 **⌘⇧P** 切到「播放模式」（圖示變綠）
4. 切到 B 視窗，每按一次 Cmd+V 就會貼上下一筆，計數器顯示進度（例如 5/20）
5. 全部貼完會跳完成提示音，按 **⌘⇧S** 可隨時全部停止

額外功能：停止錄製後在小視窗直接點任一筆 → 會把該筆寫入剪貼簿，你可以自己 Cmd+V 到任意位置（適合需要跳過某幾筆順序時使用）。

## 預設快捷鍵

| 動作 | 快捷鍵 |
|---|---|
| 開始 / 停止錄製 | ⌘⇧R |
| 開始 / 停止播放 | ⌘⇧P |
| 全部停止 | ⌘⇧S |

可在「設定」中重新綁定。

## 安裝

### 從 Releases 下載（推薦）

1. 到 [Releases](../../releases) 下載最新版 `PasteRecord-vX.Y.Z.dmg`
2. 開啟 dmg，把 `PasteRecord.app` 拖到 `/Applications`
3. 因為目前未經 Apple 公證，第一次開啟會被 Gatekeeper 阻擋。請執行：
   ```bash
   xattr -dr com.apple.quarantine /Applications/PasteRecord.app
   ```
   然後再從 Launchpad 開啟。
4. 第一次切到「播放模式」時會提示需要「輔助使用」權限：到「系統設定 > 隱私權與安全性 > 輔助使用」勾選 PasteRecord。

### 從原始碼建置

需要 macOS 13+ 以及 **完整的 Xcode 15+**（不只是 CommandLineTools，因為相依套件 `KeyboardShortcuts` 用到 SwiftUI `#Preview` 巨集，需要 Xcode 內建的巨集 plugin）。

```bash
git clone https://github.com/jeremylin0603/paste-record.git
cd paste-record
./scripts/build-app.sh         # 自動產生 dist/PasteRecord.app（universal binary）
open dist/PasteRecord.app
```

`build-app.sh` 會自動偵測並使用 `/Applications/Xcode.app`，不用手動 `xcode-select`。

或直接用 Xcode 開啟 `Package.swift` 開發。

## 權限說明

- **輔助使用 (Accessibility)**：播放模式需要它來攔截 Cmd+V 並在貼上前把下一筆內容寫入剪貼簿。錄製模式不需要這個權限。
- 本工具完全在本機運作，不會回傳任何資料。

## 技術架構

- 原生 Swift + SwiftUI（macOS 13+）
- `CGEventTap` 攔截 Cmd+V，攔截瞬間把下一筆寫入 `NSPasteboard` 後放行系統貼上
- 全域快捷鍵使用 [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts)

## 開發

```bash
swift build           # debug build
swift run             # 直接執行（dev 模式會出現在 Dock）
./scripts/build-app.sh  # 打包 .app
```

主要檔案：
- `Sources/PasteRecord/App/AppState.swift` — 狀態機（idle / recording / playing / finished）
- `Sources/PasteRecord/Clipboard/PasteInterceptor.swift` — CGEventTap 攔截 Cmd+V
- `Sources/PasteRecord/Clipboard/ClipboardMonitor.swift` — 錄製模式下監聽 pasteboard 變化
- `Sources/PasteRecord/UI/RecordingListView.swift` — 浮動小視窗 UI

## 授權

[MIT](LICENSE)
