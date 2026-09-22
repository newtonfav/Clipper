import SwiftUI

struct ClipRowView: View {
    let item: ClipItem
    var actionsEnabled: Bool = true
    var onCopy: () -> Void
    var onLocked: () -> Void = {}
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.symbolName)
                .font(.body)
                .foregroundStyle(tint)
                .frame(width: 22)
                .padding(.top, 2)
                .accessibilityLabel(item.kind.label)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(.body)
                    .lineLimit(3)
                HStack(spacing: 6) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(item.createdAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let action = kindAction {
                Button {
                    if actionsEnabled || item.kind == .code {
                        action.perform()
                    } else {
                        onLocked()
                    }
                } label: {
                    Image(systemName: action.symbol)
                        .font(.body)
                        .foregroundStyle(actionsEnabled || item.kind == .code ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(action.label)
            }
        }
        .padding(.vertical, 2)
    }

    private var tint: Color {
        switch item.kind {
        case .text: .secondary
        case .link: .blue
        case .email: .teal
        case .phone: .green
        case .code: .purple
        }
    }

    private struct KindAction {
        let label: String
        let symbol: String
        let perform: () -> Void
    }

    private var kindAction: KindAction? {
        switch item.kind {
        case .link:
            guard let url = URL(string: item.text) else { return nil }
            return KindAction(label: "Open link", symbol: "arrow.up.right.square") { openURL(url) }
        case .email:
            let address = item.text.hasPrefix("mailto:") ? item.text : "mailto:\(item.text)"
            guard let url = URL(string: address) else { return nil }
            return KindAction(label: "Send email", symbol: "envelope.open") { openURL(url) }
        case .phone:
            let digits = item.text.filter { $0.isNumber || $0 == "+" }
            guard let url = URL(string: "tel:\(digits)") else { return nil }
            return KindAction(label: "Call", symbol: "phone.arrow.up.right") { openURL(url) }
        case .code:
            return KindAction(label: "Copy code", symbol: "doc.on.doc", perform: onCopy)
        case .text:
            return nil
        }
    }
}
