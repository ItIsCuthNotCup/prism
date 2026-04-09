//
//  SoundManager.swift
//  aberration
//
//  AVAudioPlayer architecture — proven working on simulator.
//  Pre-baked WAV files for all sounds, no MIDI/sampler needed.
//
//  Key: F major pentatonic (F-G-A-C-D)
//  Instruments: Kalimba, Marimba, Music Box, Celesta
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    // MARK: - Players

    /// Pre-loaded SFX players keyed by filename (without .wav)
    private var players: [String: AVAudioPlayer] = [:]

    /// Theme music player (loops)
    private var themePlayer: AVAudioPlayer?

    // MARK: - Init

    private init() {
        configureSession()
        preloadAll()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(
            true,
            options: .notifyOthersOnDeactivation
        )
    }

    private func preloadAll() {
        // One-shot SFX
        let sfxNames = ["select",
                        "round_complete", "milestone", "game_over", "meow",
                        "celebration_clapping", "celebration_chase",
                        "celebration_binoculars", "celebration_stretch",
                        "celebration_roll"]
        for name in sfxNames {
            loadPlayer(name)
        }

        // 48 blend tones
        for i in 0..<48 {
            loadPlayer(String(format: "blend_tone_%02d", i))
        }

        // Theme — Garden Path at Noon
        if let url = Bundle.main.url(forResource: "Garden_Path_at_Noon", withExtension: "mp3") {
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.numberOfLoops = -1
                p.volume = 0.5
                p.prepareToPlay()
                themePlayer = p
            } catch {
                print("⚠️ Theme load failed: \(error)")
            }
        }
    }

    private func loadPlayer(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("⚠️ Missing \(name).wav")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            players[name] = p
        } catch {
            print("⚠️ Failed to load \(name): \(error)")
        }
    }

    // MARK: - Playback Helpers

    /// Play a named sound. Rewinds if already playing.
    private func play(_ name: String, volume: Float = 1.0) {
        guard sfxEnabled else { return }
        guard let p = players[name] else { return }
        p.volume = volume * sfxVolume
        p.currentTime = 0
        p.play()
    }

    /// Play a named sound after a delay (seconds).
    private func play(_ name: String, volume: Float = 1.0, delay: TimeInterval) {
        guard sfxEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.play(name, volume: volume)
        }
    }

    // MARK: - Settings

    var sfxEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "chr_sfx_muted") }
        set { UserDefaults.standard.set(!newValue, forKey: "chr_sfx_muted") }
    }

    var musicEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "chr_music_muted") }
        set {
            UserDefaults.standard.set(!newValue, forKey: "chr_music_muted")
            if newValue { startTheme() } else { stopTheme() }
        }
    }

    /// SFX volume level (0.0 – 1.0), stepped in 0.1 increments by the UI.
    /// Multiplied into every play() call.
    var sfxVolume: Float {
        get {
            let val = UserDefaults.standard.float(forKey: "chr_sfx_volume")
            return val == 0 && !UserDefaults.standard.bool(forKey: "chr_sfx_volume_set") ? 1.0 : val
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "chr_sfx_volume")
            UserDefaults.standard.set(true, forKey: "chr_sfx_volume_set")
        }
    }

    /// Music volume level (0.0 – 1.0), stepped in 0.1 increments by the UI.
    var musicVolume: Float {
        get {
            let val = UserDefaults.standard.float(forKey: "chr_music_volume")
            return val == 0 && !UserDefaults.standard.bool(forKey: "chr_music_volume_set") ? 0.5 : val
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "chr_music_volume")
            UserDefaults.standard.set(true, forKey: "chr_music_volume_set")
            themePlayer?.volume = newValue
        }
    }

    // MARK: - SFX: Select (Kalimba)

    /// Tile tap — plays the kalimba select sound.
    func playSelect() {
        play("select", volume: 0.5)
    }

    // MARK: - SFX: Blend Tones

    /// Warm colors (0-23) = marimba, cool (24-47) = music box.
    func playBlendTone(for color: PrismColor) {
        let index = color.wheelIndex
        let name = String(format: "blend_tone_%02d", index % 48)
        play(name, volume: 0.65)
    }

    // MARK: - SFX: Round Complete (Celesta arpeggio)

    func playRoundComplete() {
        play("round_complete", volume: 0.75)
    }

    // MARK: - SFX: Milestone

    func playMilestone() {
        play("milestone", volume: 0.8)
    }

    // MARK: - SFX: Game Over

    func playGameOver() {
        play("game_over", volume: 0.7)
    }

    // MARK: - SFX: Meow

    func playMeow() {
        play("meow", volume: 0.65)
    }

    // MARK: - Celebrations

    func playClappingCat() {
        play("celebration_clapping", volume: 0.7)
    }

    func playChaseCat() {
        play("celebration_chase", volume: 0.7)
    }

    func playBinocularsCat() {
        play("celebration_binoculars", volume: 0.7)
    }

    func playStretchCat() {
        play("celebration_stretch", volume: 0.7)
    }

    func playRollCat() {
        play("celebration_roll", volume: 0.7)
    }

    // MARK: - Theme Music

    func startTheme() {
        guard musicEnabled, let p = themePlayer else { return }
        guard !p.isPlaying else { return }
        p.currentTime = 0
        p.volume = 0.5
        p.play()
    }

    func stopTheme() {
        themePlayer?.stop()
    }

    func setMenuVolume() {
        themePlayer?.volume = 0.5
    }

    func setGameplayVolume() {
        // Smooth 400ms duck to 8% volume
        guard let player = themePlayer else { return }
        let startVol = player.volume
        let endVol: Float = 0.08
        let steps = 20
        let duration = 0.4
        for i in 0...steps {
            let frac = Float(i) / Float(steps)
            let vol = startVol + (endVol - startVol) * frac
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(frac)) { [weak self] in
                self?.themePlayer?.volume = vol
            }
        }
    }

    var isThemePlaying: Bool {
        themePlayer?.isPlaying ?? false
    }
}
