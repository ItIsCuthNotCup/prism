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
//    Theme:          8-bit cat melody loop — background music
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let musicNode = AVAudioPlayerNode()   // separate node so music doesn't stop when SFX play
    private let format: AVAudioFormat
    private let sampleRate: Double = 44100

    /// One pre-built buffer per wheel position (0-47)
    private var toneBuffers: [Int: AVAudioPCMBuffer] = [:]
    /// Soft ping when selecting a tile
    private var selectBuffer: AVAudioPCMBuffer?
    /// Ascending arpeggio for round complete
    private var roundCompleteBuffer: AVAudioPCMBuffer?
    /// Extended ascending arpeggio for milestone rounds
    private var milestoneBuffer: AVAudioPCMBuffer?
    /// Gentle descending tone for game over
    private var gameOverBuffer: AVAudioPCMBuffer?
    /// Cat meow for achievement unlocks
    private var meowBuffer: AVAudioPCMBuffer?
    /// 8-bit cat theme loop
    private var themeBuffer: AVAudioPCMBuffer?

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
        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        musicNode.volume = 0.5   // menu volume (half loudness)
        engine.mainMixerNode.outputVolume = 0.35
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        try? engine.start()
    }

    // MARK: - Buffer Generation

    private func generateAllBuffers() {
        // 48 blend tones — pentatonic-friendly mapping across ~2 octaves
        for i in 0..<PrismColor.wheelSize {
            let freq = 293.66 * pow(2.0, Double(i) / 28.0)   // ~D4 → ~D6
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

        // Cat meow: frequency sweep ≈700→1000→600 Hz with nasal harmonics
        meowBuffer = makeMeow()

        // 8-bit cat theme music
        themeBuffer = makeTheme()
    }

    // MARK: - Theme Music (loaded from theme_intro.wav)

    private func makeTheme() -> AVAudioPCMBuffer {
        // Load the zen intro clip from bundle
        guard let url = Bundle.main.url(forResource: "theme_intro", withExtension: "wav"),
              let file = try? AVAudioFile(forReading: url) else {
            // Fallback: return 1 second of silence if file missing
            let silenceCount = AVAudioFrameCount(sampleRate)
            let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: silenceCount)!
            buf.frameLength = silenceCount
            return buf
        }

        // Read the file into a buffer matching our engine format (mono 44100)
        let frameCount = AVAudioFrameCount(file.length)
        let fileFormat = file.processingFormat

        // If formats match, read directly
        if fileFormat.sampleRate == sampleRate && fileFormat.channelCount == 1 {
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try? file.read(into: buffer)
            return buffer
        }

        // Otherwise read in file's native format, then convert
        let nativeBuf = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount)!
        try? file.read(into: nativeBuf)

        guard let converter = AVAudioConverter(from: fileFormat, to: format) else {
            return nativeBuf // worst case, let the engine handle it
        }
        let convertedCount = AVAudioFrameCount(Double(frameCount) * sampleRate / fileFormat.sampleRate)
        let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: convertedCount)!
        var error: NSError?
        converter.convert(to: converted, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return nativeBuf
        }
        return converted
    }

    /// Square-wave note
    private func sqNote(
        _ data: UnsafeMutablePointer<Float>,
        _ freq: Double, _ start: Double, _ dur: Double,
        _ vol: Double, _ total: Int, _ duty: Double = 0.5
    ) {
        let s = Int(start * sampleRate)
        let n = Int(dur * sampleRate)
        let atk = Int(0.004 * sampleRate)
        let rel = Int(0.01 * sampleRate)
        let relStart = max(0, n - rel)

        for i in 0..<n {
            let f = s + i
            guard f >= 0, f < total else { continue }
            let t = Double(i) / sampleRate
            let phase = fmod(freq * t, 1.0)
            let sq = phase < duty ? 1.0 : -1.0
            var env = 1.0
            if i < atk { env = Double(i) / Double(atk) }
            else if i >= relStart { env = Double(n - i) / Double(rel) }
            data[f] += Float(sq * env * vol)
        }
    }

    /// 8-bit "mew!" — square-wave pitch sweep with nasal harmonics
    private func meowNote(
        _ data: UnsafeMutablePointer<Float>,
        _ start: Double, _ dur: Double,
        _ vol: Double, _ total: Int
    ) {
        let s = Int(start * sampleRate)
        let n = Int(dur * sampleRate)

        for i in 0..<n {
            let f = s + i
            guard f >= 0, f < total else { continue }
            let t = Double(i) / sampleRate
            let progress = t / dur

            // Pitch sweep: rise then fall
            let freq: Double
            if progress < 0.3 { freq = 700 + 300 * progress / 0.3 }
            else { freq = 1000 - 450 * (progress - 0.3) / 0.7 }

            let phase = fmod(freq * t, 1.0)
            let sq = phase < 0.5 ? 1.0 : -1.0
            // 3rd harmonic for nasal quality
            let h3 = (fmod(freq * 3.0 * t, 1.0) < 0.5 ? 1.0 : -1.0) * 0.3

            var env = 1.0
            if progress < 0.08 { env = progress / 0.08 }
            else if progress > 0.6 { env = pow(1.0 - (progress - 0.6) / 0.4, 2.0) }

            data[f] += Float((sq + h3) * env * vol)
        }
    }

    /// Tiny noise burst for percussion
    private func noiseHit(
        _ data: UnsafeMutablePointer<Float>,
        _ start: Double, _ dur: Double,
        _ vol: Double, _ total: Int
    ) {
        let s = Int(start * sampleRate)
        let n = Int(dur * sampleRate)
        for i in 0..<n {
            let f = s + i
            guard f >= 0, f < total else { continue }
            let progress = Double(i) / Double(n)
            let env = 1.0 - progress  // linear decay
            let noise = Double.random(in: -1...1)
            data[f] += Float(noise * env * vol)
        }
    }

    /// Synthesize a short cat meow — frequency sweep with formant-like harmonics
    private func makeMeow() -> AVAudioPCMBuffer {
        let duration = 0.35
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let volume = 0.30

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration  // 0→1

            // Frequency envelope: rise then fall (meow shape)
            let freq: Double
            if progress < 0.3 {
                // Rise: 700 → 1000 Hz
                freq = 700.0 + (300.0 * progress / 0.3)
            } else {
                // Fall: 1000 → 550 Hz
                freq = 1000.0 - (450.0 * (progress - 0.3) / 0.7)
            }

            // Amplitude envelope: quick attack, sustain, fade
            var env: Double
            if progress < 0.05 {
                env = progress / 0.05
            } else if progress < 0.7 {
                env = 1.0
            } else {
                env = pow(1.0 - (progress - 0.7) / 0.3, 2.0)
            }

            // Phase accumulation (needed for smooth frequency sweep)
            // Approximate: use instantaneous frequency
            let phase = 2.0 * .pi * freq * t

            // Nasal/formant timbre: strong odd harmonics
            let fundamental = sin(phase)
            let h3 = sin(phase * 3.0) * 0.35   // strong 3rd harmonic = nasal
            let h5 = sin(phase * 5.0) * 0.15   // 5th harmonic
            let h7 = sin(phase * 7.0) * 0.05   // subtle 7th

            // Add slight vibrato (cat vocal wobble)
            let vibrato = sin(2.0 * .pi * 18.0 * t) * 0.03

            let sample = (fundamental + h3 + h5 + h7) * (1.0 + vibrato) * env * volume
            data[i] = Float(sample)
        }
        return buffer
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

    // MARK: - SFX Playback

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

    func playMeow() {
        startEngine()
        guard let buffer = meowBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    // MARK: - Theme Music Playback

    func startTheme() {
        startEngine()
        guard let buffer = themeBuffer else { return }
        guard !musicNode.isPlaying else { return }
        musicNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicNode.play()
    }

    func stopTheme() {
        musicNode.stop()
    }

    /// Menu screen: half loudness
    func setMenuVolume() {
        musicNode.volume = 0.5
    }

    /// In-game: mute music
    func setGameplayVolume() {
        musicNode.volume = 0.0
    }

    var isThemePlaying: Bool {
        musicNode.isPlaying
    }
}
