//
//  FlyingLiquidOverlay.swift
//  aberration
//
//  Shows colored blobs flying from grid tile positions down to
//  the mixing lane when a blend happens.
//

import SwiftUI

/// Represents a blob of liquid flying from grid to mixing lane.
struct FlyingBlob: Identifiable {
    let id = UUID()
    let color: Color
    let startPoint: CGPoint     // in shared coordinate space
    let endPoint: CGPoint       // in shared coordinate space
    let size: CGFloat
    let isLeftSide: Bool        // enters lane tile from left or right
}

struct FlyingLiquidOverlay: View {
    let blobs: [FlyingBlob]

    var body: some View {
        ZStack {
            ForEach(blobs) { blob in
                FlyingBlobView(blob: blob)
            }
        }
        .allowsHitTesting(false)
    }
}

/// A single animated blob that flies from start to end point.
private struct FlyingBlobView: View {
    let blob: FlyingBlob

    @State private var arrived = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [blob.color.opacity(0.85), blob.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.4), .white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
            )
            .frame(width: currentSize, height: currentSize)
            .shadow(color: blob.color.opacity(0.3), radius: arrived ? 2 : 8, y: 2)
            .position(arrived ? blob.endPoint : blob.startPoint)
            .opacity(arrived ? 0 : 1)  // fade out as it arrives (liquid is now in the lane tile)
            .onAppear {
                withAnimation(.easeIn(duration: 0.35)) {
                    arrived = true
                }
            }
    }

    private var currentSize: CGFloat {
        arrived ? blob.size * 0.4 : blob.size
    }
}
