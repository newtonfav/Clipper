import Foundation

/// Insert variants offered on long-press in the keyboard.
enum TextTransform: String, CaseIterable, Identifiable, Sendable {
    case trimmed, uppercase, lowercase, firstLine

    var id: String { rawValue }

    var label: String {
        switch self {
        case .trimmed: "Trimmed"
        case .uppercase: "UPPERCASE"
        case .lowercase: "lowercase"
        case .firstLine: "First line"
        }
    }

    var symbolName: String {
        switch self {
        case .trimmed: "text.word.spacing"
        case .uppercase: "textformat.size.larger"
        case .lowercase: "textformat.size.smaller"
        case .firstLine: "text.line.first.and.arrowtriangle.forward"
        }
    }

    func apply(to text: String) -> String {
        switch self {
        case .trimmed:
            return text
                .split(whereSeparator: \.isWhitespace)
                .joined(separator: " ")
        case .uppercase:
            return text.uppercased()
        case .lowercase:
            return text.lowercased()
        case .firstLine:
            return text
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first { !$0.isEmpty } ?? ""
        }
    }
}
