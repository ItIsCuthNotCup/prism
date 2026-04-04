//
//  DailyPuzzleView.swift
//  aberration
//
//  Hue of the Day — Formula mechanic.
//  Pick 2 tiles → see what they make → pick a 3rd → does it hit the target?
//

import SwiftUI

struct DailyPuzzleView: View {
    @State private var puzzle = DailyPuzzleState()
    @State private var toastDismissWork: DispatchWorkItem? = nil
    @State private var showHowToPlay = false
    @State private var wrongShake: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    /// The swatch size used in the formula area.
    private let swatchSize: CGFloat = 56

    var body: some View {
        GeometryReader { geo in
            let maxContentWidth: CGFloat = min(geo.size.width, 500)
            let contentPadding: CGFloat = 16
            let gridInset: CGFloat = 4
            let spacing: CGFloat = 5
            let cellsArea = maxContentWidth - contentPadding * 2 - gridInset * 2
            let cellSize = max(1, (cellsArea - CGFloat(puzzle.gridSize - 1) * spacing) / CGFloat(puzzle.gridSize))

            ZStack {
                Color(hex: 0xF5F5F7)
                    .ignoresSafeArea()

                dotGridBackground

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium, design: .serif))
                                .foregroundStyle(Color(hex: 0x555555))
                        }
                        Spacer()
                        Text("Hue of the Day")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: 0x3A3A4A))
                            .tracking(1)
                        Spacer()
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17))
                            .opacity(0)
                    }
                    .padding(.bottom, 4)

                    // ── Main card ──
                    VStack(spacing: 0) {
                        // Attempts remaining
                        attemptsDisplay
                            .padding(.vertical, 6)

                        // Formula area — the core UI
                        formulaArea
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)

                        // Thin separator
                        Rectangle()
                            .fill(Color(hex: 0xDDDDDD).opacity(0.5))
                            .frame(height: 0.5)
                            .padding(.horizontal, 12)

                        // Grid
                        dailyGridView(cellSize: cellSize, spacing: spacing)
                            .padding(.top, 4)
                            .offset(x: wrongShake)

                        // Bottom buttons
                        HStack(spacing: 0) {
                            Button {
                                showHowToPlay = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("How to Play")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(Color(hex: 0x3A3A4A))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }

                            Button {
                                shareResult()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Share")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(Color(hex: 0x3A3A4A))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .opacity(puzzle.isSolved || puzzle.isFailed ? 1 : 0.2)
                            .allowsHitTesting(puzzle.isSolved || puzzle.isFailed)
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(glassCard(cornerRadius: 20))
                }
                .padding(.horizontal, contentPadding)
                .padding(.top, 4)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Win overlay
                if puzzle.isSolved {
                    solvedOverlay
                }

                // Fail overlay
                if puzzle.isFailed {
                    failedOverlay
                }

                // Bottom toast
                VStack {
                    Spacer()
                    if let toastText = puzzle.toastText {
                        topToastView(text: toastText)
                            .padding(.horizontal, contentPadding + 4)
                            .padding(.bottom, 32)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                )
                            )
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: puzzle.toastText)
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            MusicManager.shared.setGameplayVolume()
        }
        .onDisappear {
            MusicManager.shared.setMenuVolume()
        }
        .onChange(of: puzzle.toastText) { _, newText in
            toastDismissWork?.cancel()
            if newText != nil {
                let work = DispatchWorkItem {
                    withAnimation(.easeOut(duration: 0.3)) {
                        puzzle.toastText = nil
                    }
                }
                toastDismissWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: work)
            }
        }
        .onChange(of: puzzle.attempts.count) { oldVal, newVal in
            if newVal > oldVal && !puzzle.isSolved {
                shakeGrid()
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            dailyHowToPlay
        }
    }

    // MARK: - Attempts Display

    private var attemptsDisplay: some View {
        VStack(spacing: 1) {
            Text("ATTEMPTS")
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0x888888))
                .tracking(1.5)
            HStack(spacing: 4) {
                ForEach(0..<puzzle.maxAttempts, id: \.self) { i in
                    Teardrop()
                        .fill(
                            i < puzzle.attemptsRemaining
                                ? LinearGradient(
                                    colors: [Color(hex: 0xFF5E6C), Color(hex: 0xA080E0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                                : LinearGradient(
                                    colors: [Color(hex: 0xDDDDDD), Color(hex: 0xCCCCCC)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                        )
                        .frame(width: 14, height: 18)
                        .opacity(i < puzzle.attemptsRemaining ? 1.0 : 0.3)
                }
            }
            .frame(height: 26)
            .animation(.spring(response: 0.3), value: puzzle.attemptsRemaining)
        }
    }

    // MARK: - Formula Area

    /// Before 2 picks: target swatch centered with name.
    /// After 2 picks: target slides right → [Combo] + ? = [Target]
    private var formulaArea: some View {
        VStack(spacing: 6) {
            if puzzle.picks.count < 2 {
                // Target centered
                VStack(spacing: 4) {
                    colorSwatch(puzzle.targetColor, size: swatchSize)
                    Text(puzzle.targetColor.name.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0x3A3A4A))
                        .tracking(3)
                }
                .transition(.opacity)
            } else {
                // [Combo] + ? = [Target]
                let inter = puzzle.intermediate!
                HStack(spacing: 10) {
                    // Combo swatch
                    VStack(spacing: 3) {
                        colorSwatch(inter, size: swatchSize)
                        Text(inter.name)
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: 0x888888))
                    }

                    Text("+  ?  =")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0x888888))

                    // Target swatch
                    VStack(spacing: 3) {
                        colorSwatch(puzzle.targetColor, size: swatchSize)
                        Text(puzzle.targetColor.name)
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: 0x3A3A4A))
                    }
                }
                .transition(.opacity)
            }

            // Selection dots — show what's been picked
            // No selection dots — the formula area and grid highlights
            // already show what's been picked.
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: puzzle.picks.count)
    }

    /// 3 dots showing pick progress. Tap last to deselect.
    private var selectionDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                if i < puzzle.picks.count {
                    // Filled dot with tile color
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [puzzle.picks[i].highlightColor, puzzle.picks[i].color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
                        )
                        .frame(width: 18, height: 18)
                        .shadow(color: puzzle.picks[i].color.opacity(0.3), radius: 3, y: 1)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Empty dot
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(hex: 0xCCCCCC), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: puzzle.picks.count)
    }

    /// A proper-sized color swatch with gradient and glass effect.
    private func colorSwatch(_ color: PrismColor, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.2)
            .fill(
                LinearGradient(
                    colors: [color.highlightColor, color.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.4), .white.opacity(0.05), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
            )
            .frame(width: size, height: size)
            .shadow(color: color.color.opacity(0.25), radius: 8, y: 3)
    }

    // MARK: - Daily Grid

    private func dailyGridView(cellSize: CGFloat, spacing: CGFloat) -> some View {
        let columns = Array(
            repeating: GridItem(.fixed(cellSize), spacing: spacing),
            count: puzzle.gridSize
        )

        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<puzzle.gridSize * puzzle.gridSize, id: \.self) { index in
                let row = index / puzzle.gridSize
                let col = index % puzzle.gridSize
                let pos = GridPosition(row: row, col: col)

                dailyCellView(at: pos, cellSize: cellSize)
                    .frame(width: cellSize, height: cellSize)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            puzzle.selectTile(at: pos)
                        }
                    }
            }
        }
        .padding(4)
    }

    @ViewBuilder
    private func dailyCellView(at pos: GridPosition, cellSize: CGFloat) -> some View {
        let isSelected = puzzle.pickPositions.contains(pos)

        if let tileColor = puzzle.grid[pos.row][pos.col] {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [tileColor.highlightColor, tileColor.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.05), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? .white : .white.opacity(0.3),
                            lineWidth: isSelected ? 2.5 : 0.5
                        )
                )
                .shadow(
                    color: isSelected ? tileColor.color.opacity(0.5) : tileColor.color.opacity(0.15),
                    radius: isSelected ? 8 : 4,
                    y: isSelected ? 1 : 2
                )
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                .opacity(puzzle.isSolved || puzzle.isFailed ? 0.4 : 1.0)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0xE4E4EA))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(hex: 0xD0D0D8).opacity(0.7), lineWidth: 0.75)
                )
        }
    }

    // MARK: - Grid Shake

    private func shakeGrid() {
        withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
            wrongShake = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
                wrongShake = -6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                wrongShake = 0
            }
        }
    }

    // MARK: - Solved Overlay

    private var solvedOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(puzzle.scoreTier)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: 0x2A2A2A))

                colorSwatch(puzzle.targetColor, size: 70)

                Text(puzzle.targetColor.name)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: 0x4A4A5A))

                Text("\(puzzle.attempts.count)/\(puzzle.maxAttempts)")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: 0x888888))

                Button {
                    shareResult()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x2A2A2A))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Text("Back to Menu")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0xAAAAAA))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
            )
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: puzzle.isSolved)
    }

    // MARK: - Failed Overlay

    private var failedOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Not today")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: 0x2A2A2A))

                colorSwatch(puzzle.targetColor, size: 70)

                Text(puzzle.targetColor.name)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: 0x4A4A5A))

                Button {
                    shareResult()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x2A2A2A))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Text("Back to Menu")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0xAAAAAA))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
            )
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: puzzle.isFailed)
    }

    // MARK: - How to Play

    private var dailyHowToPlay: some View {
        NavigationStack {
            List {
                Section {
                    dailyRulesRow(icon: "target", color: Color(hex: 0xE63946),
                                  text: "Match the target color at the top")
                    dailyRulesRow(icon: "hand.tap.fill", color: Color(hex: 0xD4724A),
                                  text: "Tap 2 tiles — they mix into a new color")
                    dailyRulesRow(icon: "plus.circle.fill", color: Color(hex: 0xE8876B),
                                  text: "Then tap a 3rd tile to mix with the result")
                    dailyRulesRow(icon: "checkmark.circle.fill", color: Color(hex: 0x4CAF50),
                                  text: "If the final mix matches the target, you win")
                    dailyRulesRow(icon: "heart.fill", color: Color(hex: 0xFF5E6C),
                                  text: "You have 5 attempts")
                    dailyRulesRow(icon: "calendar", color: Color(hex: 0xA080E0),
                                  text: "A new puzzle every day")
                } header: {
                    Text("How to Play")
                }
            }
            .navigationTitle("Hue of the Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showHowToPlay = false }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.light)
    }

    private func dailyRulesRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x3A3A4A))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Share

    private func shareResult() {
        let text = puzzle.shareText
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Shared UI Components

    private func glassCard(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.88))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(0.9), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var dotGridBackground: some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 20
            let dotRadius: CGFloat = 0.7
            for x in stride(from: CGFloat(0), to: size.width, by: dotSpacing) {
                for y in stride(from: CGFloat(0), to: size.height, by: dotSpacing) {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.08)))
                }
            }
        }
        .ignoresSafeArea()
    }

    private func topToastView(text: String) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(Color(hex: 0x3A3A4A))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
}

#Preview {
    DailyPuzzleView()
}
