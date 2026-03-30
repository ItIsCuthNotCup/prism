import SwiftUI

struct TileView: View {
    let color: PrismColor
    var isSelected: Bool = false
    var isMatched: Bool = false
    var isBlendResult: Bool = false
    var isBlending: Bool = false

    @State private var appeared = false

    private var currentScale: CGFloat {
        if !appeared { return 0.01 }
        if isBlending { return 0.3 }
        if isMatched { return 1.15 }
        if isBlendResult { return 1.08 }
        return 1.0
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [color.highlightColor, color.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? .white : color.highlightColor.opacity(0.3),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .scaleEffect(currentScale)
            .opacity(isBlending ? 0.5 : 1.0)
            .shadow(
                color: isMatched ? .white.opacity(0.8) :
                       (isSelected ? color.color.opacity(0.6) : .clear),
                radius: isMatched ? 12 : (isSelected ? 8 : 0)
            )
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    appeared = true
                }
            }
            .animation(.easeIn(duration: 0.12), value: isBlending)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isMatched)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isBlendResult)
    }
}
