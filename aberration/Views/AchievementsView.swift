//
//  AchievementsView.swift
//  Chromatose
//
//  7×5 scrollable grid of achievement tiles styled like the game board.
//  Each tile shows a cat face that matches the achievement mood.
//  Locked tiles are greyed out; unlocked tiles glow with color.
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = 5
    private let spacing: CGFloat = 6
    private let achievements = StatsManager.allAchievements
    private let unlocked = StatsManager.shared.unlockedBadges

    @State private var selectedAchievement: StatsManager.Achievement? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0xF5F5F7)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Progress count
                    let count = achievements.filter { unlocked.contains($0.id) }.count
                    Text("\(count) / \(achievements.count)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0x457B9D), Color(hex: 0x2A9D8F)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("ACHIEVEMENTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: 0xAAAAAA))
                        .tracking(4)

                    // Scrollable 5-column grid
                    GeometryReader { geo in
                        let totalSpacing = spacing * CGFloat(columns - 1)
                        let padding: CGFloat = 20
                        let available = min(geo.size.width - padding * 2, 400)
                        let tileSize = (available - totalSpacing) / CGFloat(columns)
                        let gridWidth = available
                        let rowCount = (achievements.count + columns - 1) / columns

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: spacing) {
                                ForEach(0..<rowCount, id: \.self) { row in
                                    HStack(spacing: spacing) {
                                        ForEach(0..<columns, id: \.self) { col in
                                            let index = row * columns + col
                                            if index < achievements.count {
                                                let achievement = achievements[index]
                                                let isUnlocked = unlocked.contains(achievement.id)

                                                achievementTile(
                                                    achievement: achievement,
                                                    isUnlocked: isUnlocked,
                                                    size: tileSize
                                                )
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        if selectedAchievement?.id == achievement.id {
                                                            selectedAchievement = nil
                                                        } else {
                                                            selectedAchievement = achievement
                                                        }
                                                    }
                                                }
                                            } else {
                                                Color.clear.frame(width: tileSize, height: tileSize)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(width: gridWidth)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Selected achievement detail
                    if let selected = selectedAchievement {
                        let isUnlocked = unlocked.contains(selected.id)
                        achievementDetail(selected, isUnlocked: isUnlocked)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    Spacer()

                    // Stats summary
                    statsFooter
                }
                .padding(.top, 12)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Achievement Tile

    private func achievementTile(achievement: StatsManager.Achievement, isUnlocked: Bool, size: CGFloat) -> some View {
        let isSelected = selectedAchievement?.id == achievement.id

        return ZStack {
            if isUnlocked {
                // Show the pixel art sprite, or a colored placeholder if image is missing
                if UIImage(named: achievement.imageName) != nil {
                    Image(achievement.imageName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
                } else {
                    // Fallback: colored tile with checkmark
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: achievement.hue, saturation: 0.4, brightness: 0.95),
                                    Color(hue: achievement.hue, saturation: 0.5, brightness: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: size * 0.38, weight: .medium))
                        .foregroundStyle(Color(hue: achievement.hue, saturation: 0.6, brightness: 0.5))
                }

                // Selection border
                if isSelected {
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .strokeBorder(
                            Color(hue: achievement.hue, saturation: 0.7, brightness: 0.7),
                            lineWidth: 2.5
                        )
                }
            } else {
                // Locked tile: gray background with lock icon
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xEDEDEF), Color(hex: 0xE0E0E2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )

                RoundedRectangle(cornerRadius: size * 0.18)
                    .strokeBorder(
                        isSelected ? Color(hex: 0x999999) : .white.opacity(0.3),
                        lineWidth: isSelected ? 2.5 : 0.5
                    )

                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.24, weight: .medium))
                    .foregroundStyle(Color(hex: 0xCCCCCC))
            }
        }
        .frame(width: size, height: size)
        .shadow(
            color: isUnlocked
                ? .black.opacity(0.12)
                : .black.opacity(0.04),
            radius: isUnlocked ? 4 : 3,
            y: isUnlocked ? 2 : 1
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
    }

    // MARK: - Achievement Detail Card

    private func achievementDetail(_ achievement: StatsManager.Achievement, isUnlocked: Bool) -> some View {
        HStack(spacing: 16) {
            if isUnlocked {
                if UIImage(named: achievement.imageName) != nil {
                    Image(achievement.imageName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hue: achievement.hue, saturation: 0.4, brightness: 0.9))
                            .frame(width: 64, height: 64)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hue: achievement.hue, saturation: 0.6, brightness: 0.5))
                    }
                }
            }

            VStack(alignment: isUnlocked ? .leading : .center, spacing: 6) {
                Text(achievement.name.uppercased())
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(
                        isUnlocked
                            ? Color(hue: achievement.hue, saturation: 0.7, brightness: 0.4)
                            : Color(hex: 0x999999)
                    )
                    .tracking(2)

                Text(achievement.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: 0x777777))

                if !isUnlocked {
                    Text("LOCKED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0xBBBBBB))
                        .tracking(3)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.85))
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Footer

    private var statsFooter: some View {
        let stats = StatsManager.shared
        return HStack(spacing: 24) {
            footerStat(label: "GAMES", value: "\(stats.totalGames)")
            footerStat(label: "BLENDS", value: "\(stats.totalBlends)")
            footerStat(label: "BEST", value: "R\(stats.bestRound)")
            footerStat(label: "COLORS", value: "\(stats.discoveredColors.count)/\(PrismColor.wheelSize)")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func footerStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x3A3A4A))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color(hex: 0xBBBBBB))
                .tracking(1)
        }
    }
}
