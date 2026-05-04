import SwiftUI
import AppKit

struct RecordingListView: View {
    @ObservedObject var appState: AppState
    var onCopyItem: (RecordedItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if appState.items.isEmpty {
                emptyState
            } else {
                listContent
            }
            Divider()
            footer
        }
        .frame(minWidth: 280, minHeight: 320)
        .background(VisualEffectBlur())
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(Color(nsColor: appState.mode.color))
                .frame(width: 10, height: 10)
            Text(appState.mode.label)
                .font(.headline)
            Spacer()
            if appState.mode == .playing || appState.mode == .finished {
                Text(appState.progressText)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                Text("\(appState.items.count) 筆")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text(appState.mode == .recording ? "請複製要錄製的關鍵字…" : "尚未錄製任何項目")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var listContent: some View {
        List {
            ForEach(Array(appState.items.enumerated()), id: \.element.id) { index, item in
                ItemRow(
                    index: index + 1,
                    item: item,
                    isCurrent: appState.mode == .playing && index == appState.currentIndex,
                    isDone: index < appState.currentIndex && (appState.mode == .playing || appState.mode == .finished)
                )
                .contentShape(Rectangle())
                .onTapGesture { onCopyItem(item) }
                .contextMenu {
                    Button("複製此項") { onCopyItem(item) }
                    Button("刪除", role: .destructive) {
                        appState.removeItem(at: index)
                    }
                }
            }
            .onMove { src, dst in appState.moveItems(from: src, to: dst) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: { appState.toggleRecording() }) {
                Label(
                    appState.mode == .recording ? "停止錄製" : "開始錄製",
                    systemImage: appState.mode == .recording ? "stop.circle.fill" : "record.circle"
                )
            }
            Button(action: { appState.togglePlayback() }) {
                Label(
                    appState.mode == .playing ? "停止播放" : "開始播放",
                    systemImage: appState.mode == .playing ? "stop.circle.fill" : "play.circle"
                )
            }
            .disabled(!appState.hasItems && appState.mode != .playing)
            Spacer()
            Button(action: { appState.reset() }) {
                Image(systemName: "trash")
            }
            .disabled(appState.items.isEmpty)
            .help("清空")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct ItemRow: View {
    let index: Int
    let item: RecordedItem
    let isCurrent: Bool
    let isDone: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 22, height: 22)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(index)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(isCurrent ? .white : .primary)
                }
            }
            Text(item.preview)
                .font(.system(.body, design: .default))
                .foregroundColor(isDone ? .secondary : .primary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

private struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
