import SwiftUI
import AppKit
import Combine

@main
struct PasteRecordApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appState: appDelegate.appState)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var hotkeyManager: HotkeyManager?
    private var clipboardMonitor: ClipboardMonitor?
    private var pasteInterceptor: PasteInterceptor?
    private var menuBar: MenuBarController?
    private var panelController: FloatingPanelController?
    private var permissionWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let monitor = ClipboardMonitor(appState: appState)
        clipboardMonitor = monitor
        monitor.start()

        let interceptor = PasteInterceptor(appState: appState, clipboardMonitor: monitor)
        pasteInterceptor = interceptor

        let panel = FloatingPanelController(appState: appState) { [weak self] item in
            self?.copyItem(item)
        }
        panelController = panel

        let mb = MenuBarController(
            appState: appState,
            onShowPanel: { [weak self] in self?.panelController?.togglePanel() },
            onOpenSettings: { [weak self] in self?.openSettings() }
        )
        menuBar = mb
        mb.install()

        let hotkeys = HotkeyManager(appState: appState)
        hotkeys.register()
        hotkeyManager = hotkeys

        appState.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in self?.handleModeChange(mode) }
            .store(in: &cancellables)

        appState.$permissionAlertVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                if visible { self?.showPermissionWindow() }
            }
            .store(in: &cancellables)
    }

    private func handleModeChange(_ mode: AppMode) {
        switch mode {
        case .playing:
            pasteInterceptor?.enable()
            panelController?.showPanel()
        case .recording:
            pasteInterceptor?.disable()
            panelController?.showPanel()
        case .idle, .finished:
            pasteInterceptor?.disable()
        }
    }

    private func copyItem(_ item: RecordedItem) {
        clipboardMonitor?.markNextChangeAsSelfWritten()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.content, forType: .string)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    private func showPermissionWindow() {
        if let win = permissionWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PermissionPromptView(
            onOpenSettings: { AccessibilityHelper.openSystemSettings() },
            onDismiss: { [weak self] in
                self?.permissionWindow?.close()
                self?.permissionWindow = nil
                self?.appState.permissionAlertVisible = false
            }
        )
        let host = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: host)
        win.styleMask = [.titled, .closable]
        win.title = "PasteRecord 需要權限"
        win.isReleasedWhenClosed = false
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        permissionWindow = win
    }
}
