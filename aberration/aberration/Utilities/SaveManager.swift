//
//  SaveManager.swift
//  aberration
//
//  Named save slots for Stillhue / Blent
//

import Foundation

/// Metadata for a single named save file.
struct SaveSlot: Codable, Identifiable {
    let id: UUID
    var name: String
    let date: Date
    let score: Int
    let round: Int
    let lives: Int
    /// The full game-state payload (same JSON the autosave uses).
    let gameData: Data
}

/// Manages reading / writing named saves in the Documents directory.
/// Each save is a single JSON file: `<uuid>.blentsave`.
final class SaveManager {
    static let shared = SaveManager()

    private let fileManager = FileManager.default

    private var savesDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("SavedGames", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Public API

    /// All saved games, sorted newest-first.
    func listSaves() -> [SaveSlot] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: savesDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return urls
            .filter { $0.pathExtension == "blentsave" }
            .compactMap { url -> SaveSlot? in
                guard let data = try? Data(contentsOf: url),
                      let slot = try? JSONDecoder().decode(SaveSlot.self, from: data)
                else { return nil }
                return slot
            }
            .sorted { $0.date > $1.date }
    }

    /// Save a game with a player-chosen name. Returns the created slot.
    @discardableResult
    func save(name: String, score: Int, round: Int, lives: Int, gameData: Data) -> SaveSlot {
        let slot = SaveSlot(
            id: UUID(),
            name: name,
            date: Date(),
            score: score,
            round: round,
            lives: lives,
            gameData: gameData
        )
        let url = savesDirectory.appendingPathComponent("\(slot.id.uuidString).blentsave")
        if let encoded = try? JSONEncoder().encode(slot) {
            try? encoded.write(to: url, options: .atomic)
        }
        return slot
    }

    /// Delete a saved game by ID.
    func delete(id: UUID) {
        let url = savesDirectory.appendingPathComponent("\(id.uuidString).blentsave")
        try? fileManager.removeItem(at: url)
    }

    /// Load the raw game data for a specific save slot.
    func loadGameData(for slot: SaveSlot) -> Data? {
        return slot.gameData
    }
}
