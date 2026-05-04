import AppKit
import Combine
import SwiftUI

final class MenuBarController {
    private let appState: AppState
    private let onShowPanel: () -> Void
    private let onOpenSettings: () -> Void
    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []

    init(
        appState: AppState,
        onShowPanel: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.appState = appState
        self.onShowPanel = onShowPanel
        self.onOpenSettings = onOpenSettings
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.image = iconImage(for: appState.mode)
        item.button?.image?.isTemplate = false

        appState.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.statusItem?.button?.image = self?.iconImage(for: mode)
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        appState.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let statusLine = NSMenuItem(title: "狀態：\(appState.mode.label)（\(appState.items.count) 筆）", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        let recItem = NSMenuItem(
            title: appState.mode == .recording ? "停止錄製" : "開始錄製",
            action: #selector(toggleRecording),
            keyEquivalent: ""
        )
        recItem.target = self
        menu.addItem(recItem)

        let playItem = NSMenuItem(
            title: appState.mode == .playing ? "停止播放" : "開始播放",
            action: #selector(togglePlayback),
            keyEquivalent: ""
        )
        playItem.target = self
        playItem.isEnabled = appState.hasItems || appState.mode == .playing
        menu.addItem(playItem)

        menu.addItem(.separator())

        let panelItem = NSMenuItem(title: "顯示 / 隱藏小視窗", action: #selector(showPanel), keyEquivalent: "")
        panelItem.target = self
        menu.addItem(panelItem)

        let settingsItem = NSMenuItem(title: "設定…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "結束 PasteRecord", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func iconImage(for mode: AppMode) -> NSImage? {
        let name: String
        switch mode {
        case .idle: name = "doc.on.clipboard"
        case .recording: name = "record.circle.fill"
        case .playing: name = "play.circle.fill"
        case .finished: name = "checkmark.circle.fill"
        }
        let img = NSImage(systemSymbolName: name, accessibilityDescription: "PasteRecord")
        img?.isTemplate = (mode == .idle)
        return img
    }

    @objc private func toggleRecording() { appState.toggleRecording() }
    @objc private func togglePlayback() { appState.togglePlayback() }
    @objc private func showPanel() { onShowPanel() }
    @objc private func openSettings() { onOpenSettings() }
    @objc private func quit() { NSApp.terminate(nil) }
}
