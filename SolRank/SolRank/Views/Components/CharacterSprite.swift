import SwiftUI

/// Emoji-stacked placeholder for the eventual pixel-art sprite.
/// Renders head / shirt / pants / shoes as a vertical stack.
struct CharacterSprite: View {
    let appearance: Appearance
    var size: CGFloat = 96

    var body: some View {
        VStack(spacing: -size * 0.06) {
            Text(appearance.head).font(.system(size: size * 0.42))
            Text(appearance.shirt).font(.system(size: size * 0.34))
            Text(appearance.pants).font(.system(size: size * 0.30))
            Text(appearance.shoes).font(.system(size: size * 0.22))
        }
        .frame(width: size, height: size * 1.4)
        .padding(size * 0.12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(white: 0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }
}
