//
//  SoundManager.swift
//  aberration
//
//  Pre-baked .wav SFX via AudioToolbox SystemSoundID — zero audio-thread overhead.
//  AVAudioPlayer only for theme music (single looping instance).
//
//  Sound design:
//    Select:         soft FM ping — acknowledgment
//    Blend:          3-layer FM tone per color wheel position
//    Round complete: ascending FM arpeggio — unmistakably positive
//    Milestone:      bigger ascending sparkle — celebration
//    Game over:      gentle descending — "oh shucks", not scary
//    Theme:          theme_intro.wav — background music loop
//

import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()

    // Pre-registered SystemSoundIDs — keyed by filename (no extension).
    // AudioServicesPlaySystemSound() fires instantly with zero audio queues,
    // no render cycles, and no memory allocations at play time.
    private var sounds: [String: SystemSoundID] = [:]

    // Theme music — the only AVAudioPlayer instance in the entire app.
    private var themePlayer: AVAudioPlayer?
    private var themeURL: URL?

    // MARK: - Init

    private init() {
        configureSession()
        registerAll()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// Register every SFX .wav with AudioServices at launch.
    /// No decoding, no buffers — just file handles the OS manages internally.
    private func registerAll() {
        let names = [
            "select", "round_complete", "milestone", "game_over", "meow",
            "celebration_clapping", "celebration_chase", "celebration_binoculars",
            "celebration_stretch", "celebration_roll"
        ]
        for name in names {
            registerSound(name)
        }
        // 48 blend tones
        for i in 0..<PrismColor.wheelSize {
            registerSound(String(format: "blend_tone_%02d", i))
        }
        // Theme URL (used with AVAudioPlayer for looping — not a SystemSound)
        themeURL = Bundle.main.url(forResource: "theme_intro", withExtension: "wav")
    }

    private func registerSound(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        sounds[name] = soundID
    }

    deinit {
        for (_, soundID) in sounds {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }

    // MARK: - Toggle Settings

    var sfxEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "chr_sfx_muted") }
        set {
            UserDefaults.standard.set(!newValue, forKey: "chr_sfx_muted")
        }
    }

    var musicEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "chr_music_muted") }
        set {
            UserDefaults.standard.set(!newValue, forKey: "chr_music_muted")
            if newValue {
                startTheme()
            } else {
                stopTheme()
            }
        }
    }

    // MARK: - SFX Playback (SystemSoundID — zero overhead)

    private func playSFX(_ name: String) {
        guard sfxEnabled, let soundID = sounds[name] else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    func playSelect() {
        playSFX("select")
    }

    func playBlendTone(for color: PrismColor) {
        playSFX(String(format: "blend_tone_%02d", color.wheelIndex))
    }

    func playRoundComplete() {
        playSFX("round_complete")
    }

    func playMilestone() {
        playSFX("milestone")
    }

    func playGameOver() {
        playSFX("game_over")
    }

    func playMeow() {
        playSFX("meow")
    }

    func playClappingCat() {
        playSFX("celebration_clapping")
    }

    func playChaseCat() {
        playSFX("celebration_chase")
    }

    func playBinocularsCat() {
        playSFX("celebration_binoculars")
    }

    func playStretchCat() {
        playSFX("celebration_stretch")
    }

    func playRollCat() {
        playSFX("celebration_roll")
    }

    // MARK: - Theme Music Playback

    func startTheme() {
        guard musicEnabled else { return }
        guard themePlayer == nil || themePlayer?.isPlaying == false else { return }
        guard let url = themeURL,
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1   // infinite loop
        player.volume = 0.5         // menu volume
        player.prepareToPlay()
        player.play()
        themePlayer = player
    }

    func stopTheme() {
        themePlayer?.stop()
        themePlayer = nil
    }

    /// Menu screen: half loudness
    func setMenuVolume() {
        themePlayer?.volume = 0.5
    }

    /// In-game: barely-there ambient background
    func setGameplayVolume() {
        themePlayer?.volume = 0.08
    }

    var isThemePlaying: Bool {
        themePlayer?.isPlaying ?? false
    }
}
