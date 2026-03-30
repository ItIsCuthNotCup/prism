//
//  SoundManager.swift
//  aberration
//
//  Synthesized game tones — pre-generated at launch for zero latency.
//  Each sound is designed for clear emotional feedback:
//    Select:         soft ping — acknowledgment
//    Blend:          per-color tone — "here's what you made"
//    Round complete: ascending arpeggio — unmistakably positive
//    Milestone:      bigger ascending sparkle — celebration
//    Game over:      gentle descending — "oh shucks", not scary
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
    /// Soft ping when selecting a tile
    private var selectBuffer: AVAudioPCMBuffer?
    /// Ascending arpeggio for round complete
    private var roundCompleteBuffer: AVAudioPCMBuffer?
    /// Extended ascending arpeggio for milestone rounds
    private var milestoneBuffer: AVAudioPCMBuffer?
    /// Gentle descending tone for game over
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
        for i in 0..<24 {
            let freq = 293.66 * pow(2.0, Double(i) / 14.0)   // ~D4 → ~D6
            toneBuffers[i] = makeTone(frequency: freq, duration: 0.18)
        }

        // Tile select: soft high ping (A5)
        selectBuffer = makeTone(frequency: 880.0, duration: 0.08, volume: 0.15)

        // Round complete: ascending C major arpeggio — clearly happy
        // C5 → E5 → G5, staggered 80ms apart
        roundCompleteBuffer = makeArpeggio(
            notes: [
                (freq: 523.25, delay: 0.0),     // C5
                (freq: 659.25, delay: 0.08),    // E5
                (freq: 783.99, delay: 0.16),    // G5
            ],
            noteDuration: 0.22,
            volume: 0.30
        )

        // Milestone celebration: ascending C major up to the octave — sparkly
        // C5 → E5 → G5 → C6 → E6, staggered 65ms apart
        milestoneBuffer = makeArpeggio(
            notes: [
                (freq: 523.25, delay: 0.0),     // C5
                (freq: 659.25, delay: 0.065),   // E5
                (freq: 783.99, delay: 0.13),    // G5
                (freq: 1046.50, delay: 0.20),   // C6
                (freq: 1318.51, delay: 0.28),   // E6
            ],
            noteDuration: 0.30,
            volume: 0.30
        )

        // Game over: gentle descending minor third — "aww" not "FAIL"
        // G4 → Eb4, with warm soft timbre
        gameOverBuffer = makeArpeggio(
            notes: [
                (freq: 392.0, delay: 0.0),      // G4
                (freq: 311.13, delay: 0.20),    // Eb4
            ],
            noteDuration: 0.30,
            volume: 0.20,
            warmth: 0.85  // less harmonics = rounder, gentler
        )
    }

    // MARK: - Tone Synthesis

    /// Single tone with sine + harmonics "glass bell" timbre
    private func makeTone(frequency: Double, duration: Double, volume: Double = 0.35) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let attackFrames = Int(0.006 * sampleRate)
        let decayFrames  = Int(0.09 * sampleRate)
        let decayStart   = Int(frameCount) - decayFrames

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            var env = 1.0
            if i < attackFrames {
                env = Double(i) / Double(attackFrames)
            } else if i > decayStart {
                let progress = Double(i - decayStart) / Double(decayFrames)
                env = pow(1.0 - progress, 2.0)
            }

            let fundamental = sin(2.0 * .pi * frequency * t)
            let harmonic2   = sin(4.0 * .pi * frequency * t) * 0.15
            let harmonic3   = sin(6.0 * .pi * frequency * t) * 0.05
            let sample = (fundamental + harmonic2 + harmonic3) * env * volume

            data[i] = Float(sample)
        }
        return buffer
    }

    /// Arpeggio: notes played sequentially (staggered in time), layered into one buffer.
    /// warmth: 0.0 = full harmonics (bright), 1.0 = pure sine (warm/round)
    private func makeArpeggio(
        notes: [(freq: Double, delay: Double)],
        noteDuration: Double,
        volume: Double,
        warmth: Double = 0.0
    ) -> AVAudioPCMBuffer {
        let lastDelay = notes.map(\.delay).max() ?? 0
        let totalDuration = lastDelay + noteDuration
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        // Zero fill
        for i in 0..<Int(frameCount) { data[i] = 0 }

        // Harmonic levels (reduced by warmth parameter)
        let h2Level = 0.15 * (1.0 - warmth)
        let h3Level = 0.05 * (1.0 - warmth)

        let noteFrames = Int(noteDuration * sampleRate)
        let attackFrames = Int(0.008 * sampleRate)
        let decayPortion = 0.55  // last 55% of each note fades out
        let decayFrames = Int(noteDuration * decayPortion * sampleRate)
        let decayStart = noteFrames - decayFrames
        // Scale so notes don't clip when overlapping
        let gainPerNote = 1.0 / max(1.0, Double(notes.count) * 0.55)

        for note in notes {
            let startFrame = Int(note.delay * sampleRate)

            for i in 0..<noteFrames {
                let frame = startFrame + i
                guard frame < Int(frameCount) else { break }

                let t = Double(i) / sampleRate

                // Per-note envelope
                var env = 1.0
                if i < attackFrames {
                    env = Double(i) / Double(attackFrames)
                } else if i > decayStart {
                    let progress = Double(i - decayStart) / Double(decayFrames)
                    env = pow(1.0 - progress, 2.5)
                }

                let fundamental = sin(2.0 * .pi * note.freq * t)
                let harmonic2   = sin(4.0 * .pi * note.freq * t) * h2Level
                let harmonic3   = sin(6.0 * .pi * note.freq * t) * h3Level
                let sample = (fundamental + harmonic2 + harmonic3) * env * volume * gainPerNote

                data[frame] += Float(sample)
            }
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

    func playMilestone() {
        startEngine()
        guard let buffer = milestoneBuffer else { return }
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
