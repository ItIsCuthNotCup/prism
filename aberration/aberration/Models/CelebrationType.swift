import Foundation

/// The different random celebration animations that can pop up on round complete.
/// Add new cases here and handle them in PrismGameView.celebrationView(for:).
enum CelebrationType: CaseIterable {
    case clappingCat
    case mouseChase
    case binocularsCat
    case stretchCat
    case rollCat
    // case confettiCat     // future
}
