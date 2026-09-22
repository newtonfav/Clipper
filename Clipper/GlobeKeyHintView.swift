import SwiftUI

/// Illustration for the setup guide: hold the globe key, then pick Clipper.
struct GlobeKeyHintView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            picker
                .padding(.leading, 6)
                .padding(.bottom, 8)
            keyboardRow
        }
        .overlay(alignment: .bottomLeading) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 34))
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                .offset(x: 30, y: 6)
        }
        .padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hold the globe key on the keyboard, then choose Clipper from the list.")
    }

    private var picker: some View {
        VStack(alignment: .leading, spacing: 0) {
            pickerRow("Emoji", selected: false)
            Divider()
            pickerRow("English", selected: false)
            Divider()
            pickerRow("Clipper", selected: true)
        }
        .frame(width: 150)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }

    private func pickerRow(_ title: String, selected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(selected ? .semibold : .regular))
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(selected ? Color.accentColor.opacity(0.12) : .clear)
    }

    private var keyboardRow: some View {
        HStack(spacing: 6) {
            key(width: 46) {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))

            key(width: nil) {
                Text("space").font(.footnote)
            }
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 6))

            key(width: 70) {
                Text("return").font(.footnote)
            }
            .background(Color(uiColor: .systemGray4), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(8)
        .background(Color(uiColor: .systemGray5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func key<Content: View>(width: CGFloat?, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(width: width, height: 40)
    }
}

#Preview {
    GlobeKeyHintView()
        .padding()
}
