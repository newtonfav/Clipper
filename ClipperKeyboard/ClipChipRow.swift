import SwiftUI

/// One clip inside the keyboard. Tap inserts, long-press reveals insert variants.
struct ClipChipRow: View {
    let item: ClipItem
    let isExpanded: Bool
    let isEditing: Bool
    let canModify: Bool
    var variantsEnabled: Bool = true
    let onInsert: (String) -> Void
    let onToggleExpand: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Only this area inserts on tap and expands on long-press,
                // so the buttons beside it never compete with those gestures.
                HStack(spacing: 10) {
                    Image(systemName: item.kind.symbolName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)

                    Text(item.preview)
                        .font(.subheadline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 30)
                .contentShape(Rectangle())
                .onTapGesture { onInsert(item.text) }
                .onLongPressGesture(minimumDuration: 0.35) { onToggleExpand() }

                if isEditing {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canModify)
                    .accessibilityLabel("Delete")
                }

                Button(action: onTogglePin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.footnote)
                        .foregroundStyle(item.isPinned ? Color.orange : Color.secondary)
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canModify)
                .accessibilityLabel(item.isPinned ? "Unpin" : "Pin")
            }

            if isExpanded, !variantsEnabled {
                Label("UPPERCASE and lowercase inserts need Clipper Pro", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            } else if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(TextTransform.insertVariants) { transform in
                            Button {
                                onInsert(transform.apply(to: item.text))
                            } label: {
                                Label(transform.label, systemImage: transform.symbolName)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(KeyboardTheme.keyColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .animation(.snappy(duration: 0.2), value: isExpanded)
    }
}

enum KeyboardTheme {
    static var keyColor: Color { Color(uiColor: .systemBackground) }
    static var specialKeyColor: Color { Color(uiColor: .secondarySystemFill) }
}
