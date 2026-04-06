import SwiftUI

struct NextTilePreview: View {
    let tileColor: TileColor
    let cellSize: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Text("NEXT")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8D99AE))
                .tracking(2)

            TileView(color: tileColor, appearAnimation: false)
                .frame(width: cellSize, height: cellSize)
                .id(tileColor) // Force re-render on change
        }
    }
}
