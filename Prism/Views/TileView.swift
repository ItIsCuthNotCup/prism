import SwiftUI

struct TileView: View {
    let color: TileColor
    var isClearing: Bool = false
    var appearAnimation: Bool = true

    @State private var appeared: Bool

    init(color: TileColor, isClearing: Bool = false, appearAnimation: Bool = true) {
        self.color = color
        self.isClearing = isClearing
        self.appearAnimation = appearAnimation
        self._appeared = State(initialValue: !appearAnimation)
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
                    .strokeBorder(color.highlightColor.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(appeared ? 1.0 : 0.0)
            .opacity(isClearing ? 0 : 1)
            .onAppear {
                if appearAnimation {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        appeared = true
                    }
                } else {
                    appeared = true
                }
            }
    }
}
