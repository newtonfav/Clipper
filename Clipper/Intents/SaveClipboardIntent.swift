import AppIntents
import UIKit

/// Zero-setup App Shortcut for Siri, Spotlight and the Action Button.
///
/// iOS refuses pasteboard reads from background processes, so this intent opens the
/// app, reads the clipboard once it is in the foreground, and saves it. For a fully
/// silent save use the Back Tap shortcut (Get Clipboard → Save to Clipper) instead.
struct SaveClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Save Clipboard"
    static let description = IntentDescription("Opens Clipper briefly and saves whatever is on the clipboard.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = ClipStore()
        let outcome = ClipboardCapture.captureIfNeeded(into: store)
        let dialog: IntentDialog = switch outcome {
        case .recorded: "Saved to Clipper"
        case .duplicate, .unchanged: "Already in Clipper"
        case .noText: "Nothing to save on the clipboard"
        case .denied: "Clipper was not allowed to read the clipboard"
        }
        return .result(dialog: dialog)
    }
}
