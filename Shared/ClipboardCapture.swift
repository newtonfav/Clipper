import UIKit

/// Reads the general pasteboard at most once per change and records new text.
///
/// Reading `UIPasteboard.general.string` can show the iOS "would like to paste" prompt.
/// Everything before that read is metadata (`changeCount`, `hasStrings`) and never prompts,
/// and the change count is persisted *before* the read so a denied prompt is not repeated.
@MainActor
enum ClipboardCapture {
    enum Outcome: Equatable {
        case unchanged
        case noText
        case denied
        case recorded
        case duplicate
    }

    @discardableResult
    static func captureIfNeeded(
        into store: ClipStore,
        pasteboard: UIPasteboard = .general,
        defaults: UserDefaults = AppGroup.defaults
    ) -> Outcome {
        let key = AppGroup.DefaultsKey.lastSeenChangeCount
        let count = pasteboard.changeCount
        guard defaults.object(forKey: key) == nil || defaults.integer(forKey: key) != count else {
            return .unchanged
        }
        defaults.set(count, forKey: key)

        guard pasteboard.hasStrings else { return .noText }
        guard let text = pasteboard.string else { return .denied }
        return store.record(text) ? .recorded : .duplicate
    }
}
