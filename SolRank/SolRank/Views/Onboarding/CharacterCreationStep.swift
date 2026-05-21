import SwiftUI

struct CharacterCreationStep: View {
    @Binding var name: String
    @Binding var appearance: Appearance

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                CharacterSprite(appearance: appearance, size: 120)
                    .padding(.vertical, 8)

                TextField("Character name", text: $name)
                    .textInputAutocapitalization(.words)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .solCard()

                optionPicker(title: "Head", options: AppearanceOptions.heads, selection: $appearance.head)
                optionPicker(title: "Shirt", options: AppearanceOptions.shirts, selection: $appearance.shirt)
                optionPicker(title: "Pants", options: AppearanceOptions.pants, selection: $appearance.pants)
                optionPicker(title: "Shoes", options: AppearanceOptions.shoes, selection: $appearance.shoes)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Create Your Character")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("This avatar grows as you do.")
                .font(.system(size: 15))
                .foregroundStyle(.gray)
        }
        .padding(.top, 12)
    }

    private func optionPicker(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = option == selection.wrappedValue
                        Text(option)
                            .font(.system(size: 30))
                            .frame(width: 54, height: 54)
                            .background(isSelected ? Theme.gold.opacity(0.25) : Color(white: 0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Theme.gold : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture { selection.wrappedValue = option }
                    }
                }
            }
        }
    }
}
