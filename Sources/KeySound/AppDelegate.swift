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
    private var profileMenuItems: [NSMenuItem] = []

    private let soundPacks: [(name: String, label: String)] = [
        ("cherry-mx-brown", "Cherry MX Brown"),
        ("tactile", "Tactile"),
        ("clicky", "Clicky"),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("App launched")
        setupMenuBar()
        soundPlayer = SoundPlayer()
        debugLog("SoundPlayer created")
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

        // Volume slider
        let sliderItem = NSMenuItem()
        let sliderView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        let label = NSTextField(labelWithString: "Vol")
        label.frame = NSRect(x: 14, y: 5, width: 28, height: 20)
        label.font = NSFont.systemFont(ofSize: 12)
        let slider = NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: self, action: #selector(volumeChanged(_:)))
        slider.frame = NSRect(x: 42, y: 5, width: 140, height: 20)
        sliderView.addSubview(label)
        sliderView.addSubview(slider)
        sliderItem.view = sliderView
        menu.addItem(sliderItem)

        menu.addItem(NSMenuItem.separator())

        // Sound profile submenu
        let profileItem = NSMenuItem(title: "Sound Profile", action: nil, keyEquivalent: "")
        let profileMenu = NSMenu()
        let currentPack = UserDefaults.standard.string(forKey: "soundPack") ?? "cherry-mx-brown"

        for pack in soundPacks {
            let item = NSMenuItem(title: pack.label, action: #selector(selectProfile(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = pack.name
            item.state = pack.name == currentPack ? .on : .off
            profileMenu.addItem(item)
            profileMenuItems.append(item)
        }

        profileItem.submenu = profileMenu
        menu.addItem(profileItem)

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

    @objc private func volumeChanged(_ sender: NSSlider) {
        soundPlayer?.volume = Float(sender.doubleValue)
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let packName = sender.representedObject as? String else { return }
        debugLog("Selecting sound profile: \(packName)")

        for item in profileMenuItems {
            item.state = .off
        }
        sender.state = .on

        UserDefaults.standard.set(packName, forKey: "soundPack")
        soundPlayer?.loadSoundPack(name: packName)
    }

    @objc private func testSound() {
        debugLog("Test Sound clicked")
        soundPlayer?.playKeyDown()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func handleKeyEvent(_ event: KeyEvent) {
        guard isEnabled else { return }
        switch event {
        case .keyDown:
            soundPlayer?.playKeyDown()
        case .keyUp:
            soundPlayer?.playKeyUp()
        }
    }
}
