import AVFoundation
import Foundation

class SoundPlayer {
    private let engine = AVAudioEngine()
    private let poolSize = 8
    private var playerNodes: [AVAudioPlayerNode] = []
    private var pitchUnits: [AVAudioUnitTimePitch] = []
    private var currentIndex = 0

    private var keyDownBuffer: AVAudioPCMBuffer?
    private var keyUpBuffer: AVAudioPCMBuffer?

    init() {
        loadSounds()
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let format = keyDownBuffer?.format ?? engine.mainMixerNode.outputFormat(forBus: 0)
        debugLog("Audio engine format: \(format)")

        for i in 0..<poolSize {
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
            debugLog("Audio engine started, running=\(engine.isRunning)")
        } catch {
            debugLog("FAILED to start audio engine: \(error)")
        }
    }

    private func loadSounds() {
        keyDownBuffer = loadWAV(named: "keydown")
        keyUpBuffer = loadWAV(named: "keyup")
        debugLog("Loaded sounds: keyDown=\(keyDownBuffer?.frameLength ?? 0) frames, keyUp=\(keyUpBuffer?.frameLength ?? 0) frames")
    }

    private func loadWAV(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            debugLog("Could not find \(name).wav in bundle. Bundle path: \(Bundle.main.bundlePath)")
            debugLog("Bundle resource path: \(Bundle.main.resourcePath ?? "nil")")
            return nil
        }
        debugLog("Found \(name).wav at \(url.path)")

        do {
            let file = try AVAudioFile(forReading: url)
            debugLog("\(name).wav file format: \(file.fileFormat), processing format: \(file.processingFormat), length: \(file.length)")
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                debugLog("Could not create buffer for \(name).wav")
                return nil
            }
            try file.read(into: buffer)
            return buffer
        } catch {
            debugLog("Failed to load \(name).wav: \(error)")
            return nil
        }
    }

    func playKeyDown() {
        guard let buffer = keyDownBuffer else {
            debugLog("playKeyDown: no buffer!")
            return
        }
        debugLog("playKeyDown")
        play(buffer: buffer)
    }

    func playKeyUp() {
        guard let buffer = keyUpBuffer else {
            debugLog("playKeyUp: no buffer!")
            return
        }
        play(buffer: buffer)
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
        debugLog("play: node[\(index)] engine.running=\(engine.isRunning) player.playing=\(player.isPlaying)")
    }
}
