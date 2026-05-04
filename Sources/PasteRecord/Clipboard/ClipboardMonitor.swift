import AppKit
import Combine

final class ClipboardMonitor {
    private weak var appState: AppState?
    private var timer: Timer?
    private var lastChangeCount: Int
    private var ignoredChangeCounts: Set<Int> = []

    init(appState: AppState) {
        self.appState = appState
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Mark the next pasteboard change as self-initiated so we don't record it.
    func markNextChangeAsSelfWritten() {
        ignoredChangeCounts.insert(NSPasteboard.general.changeCount + 1)
    }

    private func tick() {
        guard let appState = appState else { return }
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        let wasIgnored = ignoredChangeCounts.contains(current)
        lastChangeCount = current
        ignoredChangeCounts.remove(current)
        ignoredChangeCounts = ignoredChangeCounts.filter { $0 > current }

        guard !wasIgnored, appState.mode == .recording else { return }
        if let str = pb.string(forType: .string), !str.isEmpty {
            appState.appendItem(str)
        }
    }
}
