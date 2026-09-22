import Foundation

/// Classifies a clip as a link, email, phone number, one-time code or plain text.
/// Foundation only, so it is safe in every extension.
enum ClipKindDetector {
    static func detect(_ raw: String) -> ClipKind {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .text }

        if isCode(text) { return .code }
        if let kind = detectWithDataDetector(text) { return kind }
        if isEmail(text) { return .email }
        return .text
    }

    // MARK: - Rules

    /// 4 to 8 digits, optionally split once by a space or dash ("123 456", "1234-5678").
    private static func isCode(_ text: String) -> Bool {
        let stripped = text.replacingOccurrences(of: "[ -]", with: "", options: .regularExpression)
        guard (4...8).contains(stripped.count) else { return false }
        guard stripped.allSatisfy(\.isNumber) else { return false }
        let separators = text.filter { $0 == " " || $0 == "-" }.count
        return separators <= 1
    }

    private static func detectWithDataDetector(_ text: String) -> ClipKind? {
        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return nil }
        let full = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: full)
        guard matches.count == 1, let match = matches.first, match.range == full else { return nil }

        switch match.resultType {
        case .link:
            guard let scheme = match.url?.scheme?.lowercased() else { return nil }
            if scheme == "mailto" { return .email }
            if scheme == "http" || scheme == "https" { return .link }
            return nil
        case .phoneNumber:
            return .phone
        default:
            return nil
        }
    }

    private static func isEmail(_ text: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}
