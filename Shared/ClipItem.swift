import Foundation

/// What a clip looks like, detected once when it is recorded.
enum ClipKind: String, Codable, Sendable, CaseIterable {
    case text, link, email, phone, code

    var symbolName: String {
        switch self {
        case .text: "text.alignleft"
        case .link: "link"
        case .email: "envelope"
        case .phone: "phone"
        case .code: "number"
        }
    }

    var label: String {
        switch self {
        case .text: "Text"
        case .link: "Link"
        case .email: "Email"
        case .phone: "Phone"
        case .code: "Code"
        }
    }
}

struct ClipItem: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var text: String
    var createdAt: Date
    var isPinned: Bool
    var kind: ClipKind
    /// Manual position among pinned items (0 is top). Ignored for history items.
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        kind: ClipKind? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.kind = kind ?? ClipKindDetector.detect(text)
        self.sortOrder = sortOrder
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, createdAt, isPinned, kind, sortOrder
    }

    /// Tolerant decoding so older files without `kind` / `sortOrder` still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        kind = try c.decodeIfPresent(ClipKind.self, forKey: .kind) ?? ClipKindDetector.detect(text)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }

    /// A one-line preview suitable for compact rows.
    var preview: String {
        TextTransform.trimmed.apply(to: text)
    }
}

/// On-disk envelope. `version` lets a future migration branch on the file shape.
struct ClipFile: Codable, Sendable {
    var version: Int = 1
    var items: [ClipItem] = []
}
