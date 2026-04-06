//
//  MusicManager.swift
//  aberration
//
//  Thin wrapper — delegates to SoundManager's music node
//  so everything runs on one proven AVAudioEngine.
//

final class MusicManager {
    static let shared = MusicManager()
    private init() {}

    func startTheme() {
        SoundManager.shared.startTheme()
    }

    func stopTheme() {
        SoundManager.shared.stopTheme()
    }

    func setMenuVolume() {
        SoundManager.shared.setMenuVolume()
    }

    func setGameplayVolume() {
        SoundManager.shared.setGameplayVolume()
    }

    var isPlaying: Bool {
        SoundManager.shared.isThemePlaying
    }
}
