import SwiftUI

struct TileView: View {
    let color: PrismColor
    var isSelected: Bool = false
    var isMatched: Bool = false
    var isBlendResult: Bool = false
    var isBlending: Bool = false
    var isHinted: Bool = false
    var showLabel: Bool = false

    @State private var appeared = false
    @State private var hintGlow = false

    private var currentScale: CGFloat {
        if !appeared { return 0.01 }
        if isBlending { return 0.3 }
        if isMatched { return 1.12 }
        if isBlendResult { return 1.06 }
        return 1.0
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            // Base color fill
            .fill(
                LinearGradient(
                    colors: [color.highlightColor, color.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // Glass specular highlight — the key "glassy" effect
            .overlay(
                LinearGradient(
                    colors: [
                        .white.opacity(0.45),
                        .white.opacity(0.15),
                        .white.opacity(0.0),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            // Subtle inner top-edge catch
            .overlay(
                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(height: 12)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            // Color label
            .overlay(
                Group {
                    if showLabel {
                        Text(color.shortName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
            )
            // Glass border
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? .white :
                        (isHinted ? .white.opacity(hintGlow ? 0.9 : 0.3) :
                        .white.opacity(0.35)),
                        lineWidth: isSelected ? 2.5 : (isHinted ? 2.5 : 0.5)
                    )
            )
            .scaleEffect(currentScale)
            .opacity(isBlending ? 0.5 : 1.0)
            .shadow(
                color: isHinted ? color.color.opacity(hintGlow ? 0.6 : 0.1) :
                       (isMatched ? color.color.opacity(0.6) :
                       (isSelected ? color.color.opacity(0.5) :
                       color.color.opacity(0.2))),
                radius: isHinted ? (hintGlow ? 10 : 3) :
                        (isMatched ? 12 : (isSelected ? 8 : 4)),
                y: isHinted ? 0 : 2
            )
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    appeared = true
                }
                if isHinted {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        hintGlow = true
                    }
                }
            }
            .onChange(of: isHinted) { _, newValue in
                if !newValue {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hintGlow = false
                    }
                }
            }
            .animation(.easeIn(duration: 0.12), value: isBlending)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isMatched)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isBlendResult)
    }
}
