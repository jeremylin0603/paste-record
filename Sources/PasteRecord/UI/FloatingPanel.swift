import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    init(contentRect: NSRect, contentView: NSView) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
        self.contentView = contentView
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class FloatingPanelController {
    private var panel: FloatingPanel?
    private let appState: AppState
    private let onCopyItem: (RecordedItem) -> Void

    init(appState: AppState, onCopyItem: @escaping (RecordedItem) -> Void) {
        self.appState = appState
        self.onCopyItem = onCopyItem
    }

    func showPanel() {
        if let panel = panel {
            panel.orderFrontRegardless()
            return
        }
        let view = RecordingListView(appState: appState, onCopyItem: onCopyItem)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 320, height: 420)

        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let rect = NSRect(
            x: screen.maxX - 340,
            y: screen.maxY - 460,
            width: 320,
            height: 420
        )
        let p = FloatingPanel(contentRect: rect, contentView: host)
        p.title = "PasteRecord"
        p.orderFrontRegardless()
        panel = p
    }

    func togglePanel() {
        if let panel = panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    func hidePanel() {
        panel?.orderOut(nil)
    }
}
