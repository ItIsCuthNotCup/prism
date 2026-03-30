//
//  SoundManager.swift
//  aberration
//
//  Synthesized blend tones — each result color has a unique pitch.
//  Soft sine+harmonic "glass" timbre. Pre-generated at launch for zero latency.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private let sampleRate: Double = 44100

    /// One pre-built buffer per wheel position (0-23)
    private var toneBuffers: [Int: AVAudioPCMBuffer] = [:]
    /// Soft "pick" sound when selecting a tile
    private var selectBuffer: AVAudioPCMBuffer?
    /// Celebratory chime for round complete
    private var roundCompleteBuffer: AVAudioPCMBuffer?
    /// Big celebration for milestone rounds (every 4th)
    private var milestoneBuffer: AVAudioPCMBuffer?
    /// Sad tone for game over
    private var gameOverBuffer: AVAudioPCMBuffer?

    // MARK: - Init

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        configureSession()
        attachNodes()
        generateAllBuffers()
        startEngine()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func attachNodes() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.35
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        try? engine.start()
    }

    // MARK: - Buffer Generation

    private func generateAllBuffers() {
        // 24 blend tones — pentatonic-friendly mapping across ~2 octaves
        // Base = C4 (261.6 Hz), stepping by whole-tone-ish intervals
        for i in 0..<24 {
            let freq = 293.66 * pow(2.0, Double(i) / 14.0)   // ~D4 → ~D6
            toneBuffers[i] = makeTone(frequency: freq, duration: 0.18)
        }

        // Tile select: soft high ping (E6) — very short, gentle
        selectBuffer = makeTone(frequency: 1318.5, duration: 0.08, volume: 0.15)

        // Round complete: bright major triad arpeggio (C5-E5-G5 simultaneous)
        roundCompleteBuffer = makeChord(
            frequencies: [523.25, 659.25, 783.99],
            duration: 0.4,
            volume: 0.25
        )

        // Milestone celebration (every 4 rounds): ascending C major 7 — sparkly
        milestoneBuffer = makeChord(
            frequencies: [523.25, 659.25, 783.99, 987.77, 1318.5],
            duration: 0.7,
            volume: 0.3
        )

        // Game over: descending minor second
        gameOverBuffer = makeTone(frequency: 220, duration: 0.35, volume: 0.2)
    }

    /// Single tone with soft sine + 2nd harmonic "glass bell" timbre
    private func makeTone(frequency: Double, duration: Double, volume: Double = 0.35) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let attackFrames  = Int(0.006 * sampleRate)   // 6 ms snap-in
        let decayFrames   = Int(0.09 * sampleRate)    // 90 ms fade-out
        let decayStart    = Int(frameCount) - decayFrames

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Envelope
            var env = 1.0
            if i < attackFrames {
                env = Double(i) / Double(attackFrames)
            } else if i > decayStart {
                // Exponential decay for natural bell feel
                let progress = Double(i - decayStart) / Double(decayFrames)
                env = pow(1.0 - progress, 2.0)
            }

            // Timbre: fundamental + soft 2nd harmonic + hint of 3rd
            let fundamental = sin(2.0 * .pi * frequency * t)
            let harmonic2   = sin(4.0 * .pi * frequency * t) * 0.15
            let harmonic3   = sin(6.0 * .pi * frequency * t) * 0.05
            let sample = (fundamental + harmonic2 + harmonic3) * env * volume

            data[i] = Float(sample)
        }
        return buffer
    }

    /// Chord: multiple frequencies layered
    private func makeChord(frequencies: [Double], duration: Double, volume: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let attackFrames = Int(0.008 * sampleRate)
        let decayFrames  = Int(0.15 * sampleRate)
        let decayStart   = Int(frameCount) - decayFrames
        let scale = 1.0 / Double(frequencies.count)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            var env = 1.0
            if i < attackFrames {
                env = Double(i) / Double(attackFrames)
            } else if i > decayStart {
                let progress = Double(i - decayStart) / Double(decayFrames)
                env = pow(1.0 - progress, 2.0)
            }

            var sum = 0.0
            for freq in frequencies {
                sum += sin(2.0 * .pi * freq * t)
                sum += sin(4.0 * .pi * freq * t) * 0.1
            }
            data[i] = Float(sum * scale * env * volume)
        }
        return buffer
    }

    // MARK: - Playback

    func playSelect() {
        startEngine()
        guard let buffer = selectBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    func playMilestone() {
        startEngine()
        guard let buffer = milestoneBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    func playBlendTone(for color: PrismColor) {
        startEngine()
        guard let buffer = toneBuffers[color.wheelIndex] else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    func playRoundComplete() {
        startEngine()
        guard let buffer = roundCompleteBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    func playGameOver() {
        startEngine()
        guard let buffer = gameOverBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }
}
