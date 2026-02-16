import ApplicationServices
import CoreGraphics
import Foundation

enum KeyEvent {
    case keyDown(timestamp: UInt64)
    case keyUp(timestamp: UInt64)
}

class KeyMonitor {
    private let callback: (KeyEvent) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?

    init(callback: @escaping (KeyEvent) -> Void) {
        self.callback = callback
    }

    func start() {
        debugLog("KeyMonitor.start(), checking accessibility...")
        if checkAccessibility() {
            debugLog("Accessibility granted, installing event tap")
            installEventTap()
        } else {
            debugLog("Accessibility NOT granted, polling...")
            pollForPermission()
        }
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func pollForPermission() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            let trusted = AXIsProcessTrusted()
            debugLog("Poll: AXIsProcessTrusted=\(trusted)")
            if trusted {
                self?.permissionTimer?.invalidate()
                self?.permissionTimer = nil
                self?.installEventTap()
            }
        }
    }

    private func installEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<KeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                let timestamp = mach_absolute_time()

                if type == .tapDisabledByTimeout {
                    debugLog("Event tap disabled by timeout, re-enabling")
                    if let tap = monitor.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                switch type {
                case .keyDown:
                    if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                        return Unmanaged.passUnretained(event)
                    }
                    monitor.callback(.keyDown(timestamp: timestamp))
                case .keyUp:
                    monitor.callback(.keyUp(timestamp: timestamp))
                default:
                    break
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else {
            debugLog("FAILED to create event tap!")
            pollForPermission()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        debugLog("Event tap installed and enabled")
    }
}
