import Foundation
import AppKit
import Combine

enum AppMode: Equatable {
    case idle
    case recording
    case playing
    case finished

    var label: String {
        switch self {
        case .idle: return "閒置"
        case .recording: return "錄製中"
        case .playing: return "播放中"
        case .finished: return "播放完成"
        }
    }

    var color: NSColor {
        switch self {
        case .idle: return .secondaryLabelColor
        case .recording: return .systemRed
        case .playing: return .systemGreen
        case .finished: return .systemBlue
        }
    }
}

final class AppState: ObservableObject {
    @Published private(set) var mode: AppMode = .idle
    @Published private(set) var items: [RecordedItem] = []
    @Published private(set) var currentIndex: Int = 0
    @Published var permissionAlertVisible: Bool = false

    var hasItems: Bool { !items.isEmpty }
    var progressText: String { "\(min(currentIndex, items.count)) / \(items.count)" }

    func toggleRecording() {
        switch mode {
        case .recording:
            stopRecording()
        case .idle, .finished:
            startRecording()
        case .playing:
            stopPlaying()
            startRecording()
        }
    }

    func togglePlayback() {
        switch mode {
        case .playing:
            stopPlaying()
        case .recording:
            stopRecording()
            startPlaying()
        case .idle, .finished:
            startPlaying()
        }
    }

    func startRecording() {
        items.removeAll()
        currentIndex = 0
        mode = .recording
    }

    func stopRecording() {
        mode = .idle
    }

    func startPlaying() {
        guard !items.isEmpty else { return }
        if !AccessibilityHelper.isTrusted() {
            permissionAlertVisible = true
            return
        }
        currentIndex = 0
        mode = .playing
    }

    func stopPlaying() {
        mode = .idle
    }

    func stopAll() {
        mode = .idle
    }

    func reset() {
        items.removeAll()
        currentIndex = 0
        mode = .idle
    }

    func appendItem(_ content: String) {
        guard !content.isEmpty else { return }
        if let last = items.last, last.content == content { return }
        items.append(RecordedItem(content: content, capturedAt: Date()))
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        if currentIndex > items.count { currentIndex = items.count }
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func advancePlayback() -> RecordedItem? {
        guard mode == .playing, items.indices.contains(currentIndex) else {
            return nil
        }
        let item = items[currentIndex]
        currentIndex += 1
        if currentIndex >= items.count {
            mode = .finished
            NSSound(named: .init("Glass"))?.play()
        }
        return item
    }
}
