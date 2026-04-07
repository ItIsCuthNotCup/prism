//
//  AwardsContainerView.swift
//  aberration
//
//  Swipeable container: Achievements ← → Stats.
//  Left swipe from Achievements goes to Stats, and vice versa.
//

import SwiftUI

struct AwardsContainerView: View {
    @State private var selectedPage = 0
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { AppTheme.shared }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.screenBgTop, theme.screenBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with page picker
                HStack {
                    // Spacer for balance
                    Color.clear
                        .frame(width: 50, height: 1)

                    Spacer()

                    pagePicker

                    Spacer()

                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .frame(width: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                // Swipeable pages
                TabView(selection: $selectedPage) {
                    AchievementsPageView()
                        .tag(0)
                    StatsPageView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private var pagePicker: some View {
        HStack(spacing: 0) {
            pageTab("Awards", index: 0)
            pageTab("Stats", index: 1)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.isDark ? Color(hex: 0x2A2A32) : Color(hex: 0xEEEEF0))
        )
    }

    private func pageTab(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPage = index
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: selectedPage == index ? .bold : .medium, design: .rounded))
                .foregroundStyle(selectedPage == index ? theme.textPrimary : theme.textMuted)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if selectedPage == index {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.cardFill)
                                .shadow(color: .black.opacity(theme.shadowOpacity), radius: 4, y: 2)
                        }
                    }
                )
        }
    }
}

// MARK: - Achievements Page (extracted from AchievementsView, no NavigationStack/toolbar)

struct AchievementsPageView: View {
    private let columns = 5
    private let spacing: CGFloat = 6
    private let achievements = StatsManager.allAchievements
    private let unlocked = StatsManager.shared.unlockedBadges
    private var theme: AppTheme { AppTheme.shared }

    @State private var selectedAchievement: StatsManager.Achievement? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Progress count
            let count = achievements.filter { unlocked.contains($0.id) }.count
            Text("\(count) / \(achievements.count)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xD4724A), Color(hex: 0xE8876B)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("ACHIEVEMENTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.textTertiary)
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

    // MARK: - Achievement Tile

    private func achievementTile(achievement: StatsManager.Achievement, isUnlocked: Bool, size: CGFloat) -> some View {
        let isSelected = selectedAchievement?.id == achievement.id

        return ZStack {
            if isUnlocked {
                if UIImage(named: achievement.imageName) != nil {
                    Image(achievement.imageName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
                } else {
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

                if isSelected {
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .strokeBorder(
                            Color(hue: achievement.hue, saturation: 0.7, brightness: 0.7),
                            lineWidth: 2.5
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(
                        LinearGradient(
                            colors: [theme.lockedBgTop, theme.lockedBgBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(theme.isDark ? 0.1 : 0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )

                RoundedRectangle(cornerRadius: size * 0.18)
                    .strokeBorder(
                        isSelected ? theme.textMuted : .white.opacity(theme.isDark ? 0.1 : 0.3),
                        lineWidth: isSelected ? 2.5 : 0.5
                    )

                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.24, weight: .medium))
                    .foregroundStyle(theme.textQuaternary)
            }
        }
        .frame(width: size, height: size)
        .shadow(
            color: isUnlocked ? .black.opacity(0.12) : .black.opacity(0.04),
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
                            ? Color(hue: achievement.hue, saturation: theme.isDark ? 0.5 : 0.7, brightness: theme.isDark ? 0.8 : 0.4)
                            : theme.textMuted
                    )
                    .tracking(2)

                Text(achievement.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                if !isUnlocked {
                    Text("LOCKED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.textTertiary)
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
                    .fill(theme.cardFill.opacity(theme.cardFillOpacity))
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(theme.isDark ? 0.15 : 0.6), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(theme.shadowOpacity), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Footer

    private var statsFooter: some View {
        let stats = StatsManager.shared
        return HStack(spacing: 24) {
            footerStat(label: "GAMES", value: "\(stats.totalGames)")
            footerStat(label: "MIXES", value: "\(stats.totalBlends)")
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
                .foregroundStyle(theme.textPrimaryAlt)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.textTertiary)
                .tracking(1)
        }
    }
}

// MARK: - Stats Page (embedded, no NavigationStack)

struct StatsPageView: View {
    private let stats = StatsManager.shared
    private var theme: AppTheme { AppTheme.shared }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sub-picker: Classic vs Daily
                statsSubPicker
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    @State private var selectedSub = 0

    private var statsSubPicker: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                subTab("Classic", index: 0)
                subTab("Hue of the Day", index: 1)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.isDark ? Color(hex: 0x2A2A32) : Color(hex: 0xEEEEF0))
            )

            if selectedSub == 0 {
                classicStats
            } else {
                dailyStats
            }
        }
    }

    private func subTab(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedSub = index
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: selectedSub == index ? .bold : .medium, design: .rounded))
                .foregroundStyle(selectedSub == index ? theme.textPrimary : theme.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if selectedSub == index {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.cardFill)
                                .shadow(color: .black.opacity(theme.shadowOpacity), radius: 4, y: 2)
                        }
                    }
                )
        }
    }

    // MARK: - Classic Stats

    private var classicStats: some View {
        VStack(spacing: 14) {
            statsCard {
                HStack(spacing: 0) {
                    heroStat(value: "\(stats.totalGames)", label: "GAMES")
                    heroStat(value: "\(stats.totalBlends)", label: "MIXES")
                    heroStat(value: "R\(stats.bestRound)", label: "BEST")
                    heroStat(value: "\(stats.bestScore)", label: "HIGH SCORE")
                }
            }

            statsCard {
                VStack(spacing: 10) {
                    cardHeader("Color Discovery", icon: "paintpalette.fill", color: Color(hex: 0xD4724A))
                    VStack(spacing: 4) {
                        HStack {
                            Text("\(stats.discoveredColors.count) of \(PrismColor.wheelSize)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.textPrimaryAlt)
                            Spacer()
                            Text("\(Int(round(Double(stats.discoveredColors.count) / Double(PrismColor.wheelSize) * 100)))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: 0xD4724A))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.isDark ? Color(hex: 0x2A2A32) : Color(hex: 0xEEEEF0))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0xD4724A), Color(hex: 0xE8876B)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(stats.discoveredColors.count) / CGFloat(max(PrismColor.wheelSize, 1)))
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }

            statsCard {
                VStack(spacing: 10) {
                    cardHeader("Performance", icon: "chart.bar.fill", color: Color(hex: 0xA080E0))
                    VStack(spacing: 8) {
                        statRow(label: "Total Rounds", value: "\(stats.totalRounds)")
                        statRow(label: "Perfect Rounds", value: "\(stats.perfectRounds)")
                        statRow(label: "Under Par", value: "\(stats.underParCount)")
                        statRow(label: "Best Par Streak", value: "\(stats.bestParStreak)")
                    }
                }
            }

            statsCard {
                VStack(spacing: 10) {
                    cardHeader("Items", icon: "sparkles", color: Color(hex: 0xF59E0B))
                    HStack(spacing: 0) {
                        miniStat(value: "\(stats.livesUsed)", label: "Lives\nUsed", color: Color(hex: 0xFF5E6C))
                        miniStat(value: "\(stats.bonusLivesEarned)", label: "Bonus\nLives", color: Color(hex: 0xA080E0))
                        miniStat(value: "\(stats.undosUsed)", label: "Undos\nUsed", color: Color(hex: 0xF59E0B))
                        miniStat(value: "\(stats.goldenTilesUsed)", label: "Golden\nTiles", color: Color(hex: 0xD4724A))
                    }
                }
            }
        }
    }

    // MARK: - Daily Stats

    private var dailyStats: some View {
        VStack(spacing: 14) {
            statsCard {
                HStack(spacing: 0) {
                    heroStat(value: "\(stats.dailyPlayed)", label: "PLAYED")
                    heroStat(value: "\(stats.dailyWinPercent)%", label: "WIN %")
                    heroStat(value: "\(stats.dailyCurrentStreak)", label: "STREAK")
                    heroStat(value: "\(stats.dailyMaxStreak)", label: "MAX")
                }
            }

            statsCard {
                VStack(spacing: 10) {
                    cardHeader("Guess Distribution", icon: "chart.bar.fill", color: Color(hex: 0xA080E0))

                    let dist = stats.dailyGuessDistribution
                    let maxVal = max(dist.max() ?? 1, 1)

                    VStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            HStack(spacing: 8) {
                                Text("\(i + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.textPrimaryAlt)
                                    .frame(width: 16)

                                GeometryReader { geo in
                                    let barWidth = max(
                                        geo.size.width * CGFloat(dist[i]) / CGFloat(maxVal),
                                        dist[i] > 0 ? 24 : 8
                                    )
                                    HStack(spacing: 0) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                i == bestGuessIndex(dist)
                                                    ? LinearGradient(
                                                        colors: [Color(hex: 0xD4724A), Color(hex: 0xE8876B)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [theme.textQuaternary, theme.textTertiary],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                            )
                                            .frame(width: barWidth, height: 22)
                                            .overlay(alignment: .trailing) {
                                                Text("\(dist[i])")
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white)
                                                    .padding(.trailing, 6)
                                            }
                                        Spacer()
                                    }
                                }
                                .frame(height: 22)
                            }
                        }
                    }
                }
            }

            if stats.dailyPlayed > 0 {
                statsCard {
                    VStack(spacing: 10) {
                        cardHeader("Streaks", icon: "flame.fill", color: Color(hex: 0xFF5E6C))
                        HStack(spacing: 0) {
                            miniStat(value: "\(stats.dailyCurrentStreak)", label: "Current\nStreak", color: Color(hex: 0xFF5E6C))
                            miniStat(value: "\(stats.dailyMaxStreak)", label: "Best\nStreak", color: Color(hex: 0xD4724A))
                            miniStat(value: "\(stats.dailyWins)", label: "Total\nWins", color: Color(hex: 0x4CAF50))
                            miniStat(value: "\(stats.dailyPlayed - stats.dailyWins)", label: "Total\nLosses", color: theme.textMuted)
                        }
                    }
                }
            }
        }
    }

    private func bestGuessIndex(_ dist: [Int]) -> Int {
        guard let maxVal = dist.max(), maxVal > 0 else { return 0 }
        return dist.firstIndex(of: maxVal) ?? 0
    }

    // MARK: - Reusable Components

    private func statsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardFill.opacity(theme.cardFillOpacity))
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardMaterial)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.cardBorderColor.opacity(theme.cardBorderOpacity), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(theme.shadowOpacity), radius: 12, y: 4)
        )
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(theme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func cardHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimaryAlt)
            Spacer()
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimaryAlt)
        }
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AwardsContainerView()
}
