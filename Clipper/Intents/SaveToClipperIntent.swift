import AppIntents

/// Lets Shortcuts save text without opening the app. Pair with "Get Clipboard"
/// and bind the shortcut to Back Tap or the Action Button for one-tap capture.
struct SaveToClipperIntent: AppIntent {
    static let title: LocalizedStringResource = "Save to Clipper"
    static let description = IntentDescription("Saves text to Clipper. Optionally pins it.")
    static let openAppWhenRun = false

    @Parameter(title: "Text", inputOptions: String.IntentInputOptions(multiline: true))
    var text: String

    @Parameter(title: "Pin", default: false)
    var pin: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$text) to Clipper") {
            \.$pin
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let store = ClipStore()
        let changed = store.record(text, pinned: pin)
        let dialog: IntentDialog = changed
            ? (pin ? "Pinned in Clipper" : "Saved to Clipper")
            : "Already in Clipper"
        return .result(value: changed, dialog: dialog)
    }
}
