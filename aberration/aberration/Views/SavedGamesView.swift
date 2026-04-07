//
//  SavedGamesView.swift
//  aberration
//
//  Browse, load, and delete named save slots.
//

import SwiftUI

struct SavedGamesView: View {
    @Binding var isPresented: Bool       // controls the parent settings sheet
    var onLoad: (Data) -> Void           // passes raw game-state JSON back

    @State private var saves: [SaveSlot] = []
    @State private var deleteTarget: SaveSlot? = nil
    @State private var showDeleteConfirm = false

    private var theme: AppTheme { AppTheme.shared }

    var body: some View {
        Group {
            if saves.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(theme.textTertiary)
                    Text("No saved games yet")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textMuted)
                    Text("Save your progress from the Settings menu")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(theme.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(saves) { slot in
                            saveRow(slot)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(theme.screenBg)
        .navigationTitle("Saved Games")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Save?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        SaveManager.shared.delete(id: target.id)
                        saves.removeAll { $0.id == target.id }
                    }
                }
            }
        } message: {
            if let target = deleteTarget {
                Text("Remove \"\(target.name)\"? This cannot be undone.")
            }
        }
        .onAppear { saves = SaveManager.shared.listSaves() }
    }

    // MARK: - Row

    private func saveRow(_ slot: SaveSlot) -> some View {
        Button {
            onLoad(slot.gameData)
            isPresented = false
        } label: {
            HStack(spacing: 14) {
                // Icon
                VStack {
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: 0xA080E0))
                }
                .frame(width: 40)

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(slot.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textPrimaryAlt)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Label("Round \(slot.round)", systemImage: "flag.fill")
                        Label("\(slot.score)", systemImage: "star.fill")
                        Label("\(slot.lives)", systemImage: "heart.fill")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)

                    Text(slot.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(theme.textTertiary)
                }

                Spacer()

                // Delete button
                Button {
                    deleteTarget = slot
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: 0xCC4444).opacity(0.6))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardFill)
                    .shadow(color: .black.opacity(theme.shadowOpacity), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
