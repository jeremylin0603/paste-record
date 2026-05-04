import AppKit
import CoreGraphics

private let kVKey: Int64 = 9

final class PasteInterceptor {
    private weak var appState: AppState?
    private weak var clipboardMonitor: ClipboardMonitor?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(appState: AppState, clipboardMonitor: ClipboardMonitor) {
        self.appState = appState
        self.clipboardMonitor = clipboardMonitor
    }

    @discardableResult
    func enable() -> Bool {
        guard eventTap == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let interceptor = Unmanaged<PasteInterceptor>.fromOpaque(refcon).takeUnretainedValue()
                return interceptor.handle(type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            return false
        }

        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        runLoopSource = src
        return true
    }

    func disable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    deinit { disable() }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let cmdOnly = flags.contains(.maskCommand)
            && !flags.contains(.maskShift)
            && !flags.contains(.maskAlternate)
            && !flags.contains(.maskControl)
        guard keycode == kVKey, cmdOnly else { return Unmanaged.passUnretained(event) }

        // Callback runs on main thread because the run loop source is on main run loop.
        guard let appState = appState, appState.mode == .playing else {
            return Unmanaged.passUnretained(event)
        }
        guard let item = appState.advancePlayback() else {
            return Unmanaged.passUnretained(event)
        }

        clipboardMonitor?.markNextChangeAsSelfWritten()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.content, forType: .string)
        return Unmanaged.passUnretained(event)
    }
}
