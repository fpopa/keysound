import AVFoundation
import Foundation

class SoundPlayer {
    private let engine = AVAudioEngine()
    private let poolSize = 8
    private var playerNodes: [AVAudioPlayerNode] = []
    private var pitchUnits: [AVAudioUnitTimePitch] = []
    private var currentIndex = 0

    private var keyDownBuffers: [AVAudioPCMBuffer] = []
    private var keyUpBuffers: [AVAudioPCMBuffer] = []
    private var lastKeyDownIndex = -1

    var volume: Float = 0.5 {
        didSet { engine.mainMixerNode.outputVolume = volume }
    }

    init() {
        let savedPack = UserDefaults.standard.string(forKey: "soundPack") ?? "cherry-mx-brown"
        loadSoundPack(name: savedPack)
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let format = keyDownBuffers.first?.format ?? engine.mainMixerNode.outputFormat(forBus: 0)
        debugLog("Audio engine format: \(format)")

        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            pitch.rate = 1.0

            engine.attach(player)
            engine.attach(pitch)
            engine.connect(player, to: pitch, format: format)
            engine.connect(pitch, to: engine.mainMixerNode, format: format)

            playerNodes.append(player)
            pitchUnits.append(pitch)
        }
        debugLog("Attached \(poolSize) player nodes")

        do {
            try engine.start()
            engine.mainMixerNode.outputVolume = volume
            debugLog("Audio engine started, running=\(engine.isRunning)")
        } catch {
            debugLog("FAILED to start audio engine: \(error)")
        }
    }

    func loadSoundPack(name: String) {
        keyDownBuffers = []
        keyUpBuffers = []

        guard let soundsURL = Bundle.main.resourceURL?.appendingPathComponent("sounds/\(name)") else {
            debugLog("Could not find sounds/\(name) in bundle")
            return
        }

        debugLog("Loading sound pack: \(name) from \(soundsURL.path)")

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: soundsURL, includingPropertiesForKeys: nil) else {
            debugLog("Could not list files in \(soundsURL.path)")
            return
        }

        for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let filename = file.lastPathComponent
            guard filename.hasSuffix(".wav") else { continue }

            if filename.hasPrefix("keydown_"), let buf = loadWAV(url: file) {
                keyDownBuffers.append(buf)
            } else if filename.hasPrefix("keyup_"), let buf = loadWAV(url: file) {
                keyUpBuffers.append(buf)
            }
        }

        lastKeyDownIndex = -1
        debugLog("Loaded pack '\(name)': \(keyDownBuffers.count) keydown, \(keyUpBuffers.count) keyup")
    }

    private func loadWAV(url: URL) -> AVAudioPCMBuffer? {
        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                debugLog("Could not create buffer for \(url.lastPathComponent)")
                return nil
            }
            try file.read(into: buffer)
            return buffer
        } catch {
            debugLog("Failed to load \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    func playKeyDown() {
        guard !keyDownBuffers.isEmpty else {
            debugLog("playKeyDown: no buffers!")
            return
        }
        var idx = Int.random(in: 0..<keyDownBuffers.count)
        if keyDownBuffers.count > 1 && idx == lastKeyDownIndex {
            idx = (idx + 1) % keyDownBuffers.count
        }
        lastKeyDownIndex = idx
        play(buffer: keyDownBuffers[idx])
    }

    func playKeyUp() {
        guard !keyUpBuffers.isEmpty else { return }
        let idx = Int.random(in: 0..<keyUpBuffers.count)
        play(buffer: keyUpBuffers[idx])
    }

    private func play(buffer: AVAudioPCMBuffer) {
        let index = currentIndex % poolSize
        currentIndex += 1

        let player = playerNodes[index]
        let pitch = pitchUnits[index]

        let factor = Double.random(in: 0.95...1.05)
        let cents = Float(1200.0 * log2(factor))
        pitch.pitch = cents

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
}
