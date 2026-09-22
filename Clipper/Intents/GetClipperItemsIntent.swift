import AppIntents

enum ClipSource: String, AppEnum {
    case all, pinned, recent

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Clips")
    static let caseDisplayRepresentations: [ClipSource: DisplayRepresentation] = [
        .all: "All",
        .pinned: "Pinned",
        .recent: "Recent",
    ]
}

/// Returns clips as text so other Shortcuts actions can use them.
struct GetClipperItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Clipper Items"
    static let description = IntentDescription("Returns pinned and recent clips as text.")
    static let openAppWhenRun = false

    @Parameter(title: "Which", default: .all)
    var source: ClipSource

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$source) clips")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let store = ClipStore(postsNotifications: false)
        let items: [ClipItem] = switch source {
        case .all: store.pinned + store.history
        case .pinned: store.pinned
        case .recent: store.history
        }
        return .result(value: items.map(\.text))
    }
}
