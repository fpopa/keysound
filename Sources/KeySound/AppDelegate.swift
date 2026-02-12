import AppKit

let logFile: URL = {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("keysound-debug.log")
    // Clear on launch
    try? "".write(to: url, atomically: true, encoding: .utf8)
    return url
}()

func debugLog(_ msg: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(msg)\n"
    if let fh = try? FileHandle(forWritingTo: logFile) {
        fh.seekToEndOfFile()
        fh.write(line.data(using: .utf8)!)
        fh.closeFile()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var enabledMenuItem: NSMenuItem!
    private var keyMonitor: KeyMonitor?
    private var soundPlayer: SoundPlayer?
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("App launched")
        setupMenuBar()
        soundPlayer = SoundPlayer()
        debugLog("SoundPlayer created, keyDownBuffer=\(soundPlayer != nil ? "ok" : "nil")")
        keyMonitor = KeyMonitor { [weak self] event in
            self?.handleKeyEvent(event)
        }
        keyMonitor?.start()
        debugLog("KeyMonitor started")
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeySound")
        }

        let menu = NSMenu()

        enabledMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledMenuItem.target = self
        enabledMenuItem.state = .on
        menu.addItem(enabledMenuItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(title: "Test Sound", action: #selector(testSound), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit KeySound", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enabledMenuItem.state = isEnabled ? .on : .off
        debugLog("Toggled enabled=\(isEnabled)")
    }

    @objc private func testSound() {
        debugLog("Test Sound clicked")
        soundPlayer?.playKeyDown()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func handleKeyEvent(_ event: KeyEvent) {
        debugLog("handleKeyEvent: \(event), enabled=\(isEnabled)")
        guard isEnabled else { return }
        switch event {
        case .keyDown:
            soundPlayer?.playKeyDown()
        case .keyUp:
            soundPlayer?.playKeyUp()
        }
    }
}
