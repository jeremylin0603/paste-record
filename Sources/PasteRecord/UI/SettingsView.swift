import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Form {
            Section("快捷鍵") {
                KeyboardShortcuts.Recorder("開始 / 停止錄製", name: .toggleRecording)
                KeyboardShortcuts.Recorder("開始 / 停止播放", name: .togglePlayback)
                KeyboardShortcuts.Recorder("全部停止", name: .stopAll)
            }
            Section("權限") {
                HStack {
                    Image(systemName: AccessibilityHelper.isTrusted() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(AccessibilityHelper.isTrusted() ? .green : .orange)
                    Text(AccessibilityHelper.isTrusted() ? "已授予輔助使用權限" : "尚未授予輔助使用權限（播放模式需要）")
                    Spacer()
                    Button("開啟系統設定") {
                        AccessibilityHelper.openSystemSettings()
                    }
                }
            }
            Section {
                Text("PasteRecord 版本 0.1.1")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 360)
    }
}
