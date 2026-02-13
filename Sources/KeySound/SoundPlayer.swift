import AudioToolbox
import AVFoundation
import Foundation

class SoundPlayer {
    private let engine = AVAudioEngine()
    private let poolSize = 8
    private var playerNodes: [AVAudioPlayerNode] = []
    private var varispeedUnits: [AVAudioUnitVarispeed] = []
    private var currentIndex = 0

    private var keyDownBuffers: [AVAudioPCMBuffer] = []
    private var keyUpBuffers: [AVAudioPCMBuffer] = []
    private var lastKeyDownIndex = -1

    var pitchVariationRange: Float = 0.05

    var volume: Float = 0.5 {
        didSet { engine.mainMixerNode.outputVolume = volume }
    }

    init() {
        let savedPack = UserDefaults.standard.string(forKey: "soundPack") ?? "cherry-mx-brown"
        loadSoundPack(name: savedPack)
        if let saved = UserDefaults.standard.object(forKey: "pitchVariationRange") as? Float {
            pitchVariationRange = saved
        }
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        // Reduce I/O buffer size: 128 frames ≈ 2.9ms at 44100Hz (default is 512 ≈ 11.6ms)
        if let audioUnit = engine.outputNode.audioUnit {
            var bufferSize: UInt32 = 128
            let status = AudioUnitSetProperty(
                audioUnit,
                kAudioDevicePropertyBufferFrameSize,
                kAudioUnitScope_Global, 0,
                &bufferSize, UInt32(MemoryLayout<UInt32>.size))
            debugLog("Set buffer size to 128 frames: status=\(status)")
        }

        let format = keyDownBuffers.first?.format ?? engine.mainMixerNode.outputFormat(forBus: 0)
        debugLog("Audio engine format: \(format)")

        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            let varispeed = AVAudioUnitVarispeed()
            varispeed.rate = 1.0

            engine.attach(player)
            engine.attach(varispeed)
            engine.connect(player, to: varispeed, format: format)
            engine.connect(varispeed, to: engine.mainMixerNode, format: format)

            playerNodes.append(player)
            varispeedUnits.append(varispeed)
        }
        debugLog("Attached \(poolSize) player nodes with varispeed")

        do {
            try engine.start()
            engine.mainMixerNode.outputVolume = volume
            debugLog("Audio engine started, running=\(engine.isRunning)")
            debugLog("outputNode.presentationLatency: \(engine.outputNode.presentationLatency)")
            debugLog("outputNode.latency: \(engine.outputNode.latency)")
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

    func playKeyDown(eventTime: UInt64 = 0) {
        guard !keyDownBuffers.isEmpty else {
            debugLog("playKeyDown: no buffers!")
            return
        }
        var idx = Int.random(in: 0..<keyDownBuffers.count)
        if keyDownBuffers.count > 1 && idx == lastKeyDownIndex {
            idx = (idx + 1) % keyDownBuffers.count
        }
        lastKeyDownIndex = idx
        play(buffer: keyDownBuffers[idx], eventTime: eventTime)
    }

    func playKeyUp(eventTime: UInt64 = 0) {
        guard !keyUpBuffers.isEmpty else { return }
        let idx = Int.random(in: 0..<keyUpBuffers.count)
        play(buffer: keyUpBuffers[idx], eventTime: eventTime)
    }

    private func play(buffer: AVAudioPCMBuffer, eventTime: UInt64) {
        let index = currentIndex % poolSize
        currentIndex += 1

        let player = playerNodes[index]
        let varispeed = varispeedUnits[index]

        if pitchVariationRange > 0 {
            varispeed.rate = Float.random(in: (1 - pitchVariationRange)...(1 + pitchVariationRange))
        } else {
            varispeed.rate = 1.0
        }

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()

        if eventTime != 0 {
            var info = mach_timebase_info_data_t()
            mach_timebase_info(&info)
            let now = mach_absolute_time()
            let elapsedTicks = now - eventTime
            let elapsedNs = elapsedTicks * UInt64(info.numer) / UInt64(info.denom)
            let elapsedMs = Double(elapsedNs) / 1_000_000.0
            debugLog("play() software overhead: \(String(format: "%.2f", elapsedMs))ms")
        }
    }
}
