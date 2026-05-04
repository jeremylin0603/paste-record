import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self(
        "toggleRecording",
        default: .init(.r, modifiers: [.command, .shift])
    )
    static let togglePlayback = Self(
        "togglePlayback",
        default: .init(.p, modifiers: [.command, .shift])
    )
    static let stopAll = Self(
        "stopAll",
        default: .init(.s, modifiers: [.command, .shift])
    )
}

final class HotkeyManager {
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    func register() {
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
            self?.appState?.toggleRecording()
        }
        KeyboardShortcuts.onKeyDown(for: .togglePlayback) { [weak self] in
            self?.appState?.togglePlayback()
        }
        KeyboardShortcuts.onKeyDown(for: .stopAll) { [weak self] in
            self?.appState?.stopAll()
        }
    }
}
