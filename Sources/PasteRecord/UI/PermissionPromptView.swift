import SwiftUI

struct PermissionPromptView: View {
    var onOpenSettings: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.title)
                    .foregroundColor(.orange)
                Text("需要「輔助使用」權限")
                    .font(.title3.bold())
            }
            Text("PasteRecord 在「播放模式」需要攔截 Cmd+V 並把下一筆內容寫入剪貼簿。請到「系統設定 > 隱私權與安全性 > 輔助使用」勾選 PasteRecord，然後重新嘗試播放。")
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("稍後再說") { onDismiss() }
                Button("開啟系統設定") {
                    onOpenSettings()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
