import SwiftUI

extension View {
    /// Applies the standard card styling used throughout SolRank
    func solCard() -> some View {
        self
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

