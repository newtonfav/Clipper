import Observation
import UIKit

/// Everything the SwiftUI keyboard needs from the input view controller,
/// so views never touch UIKit directly.
@MainActor
@Observable
final class KeyboardActions {
    private(set) var hasFullAccess = false
    private(set) var needsInputModeSwitchKey = true
    private(set) var isDarkAppearance = false
    /// Incremented whenever a new clip is captured while the keyboard is open.
    private(set) var captureCount = 0

    @ObservationIgnored private weak var controller: UIInputViewController?

    init(controller: UIInputViewController) {
        self.controller = controller
    }

    var inputViewController: UIInputViewController? { controller }

    /// Re-reads values that only become accurate once the keyboard is on screen.
    func refresh() {
        guard let controller else { return }
        hasFullAccess = controller.hasFullAccess
        needsInputModeSwitchKey = controller.needsInputModeSwitchKey
        isDarkAppearance = controller.textDocumentProxy.keyboardAppearance == .dark
    }

    /// Inserts a clip and, if enabled, hands control back to the next keyboard.
    func insert(_ text: String) {
        controller?.textDocumentProxy.insertText(text)
        if AppSettings.autoReturnAfterInsert {
            controller?.advanceToNextInputMode()
        }
    }

    func noteCapture() { captureCount += 1 }

    func insertSpace() { controller?.textDocumentProxy.insertText(" ") }
    func insertNewline() { controller?.textDocumentProxy.insertText("\n") }
    func deleteBackward() { controller?.textDocumentProxy.deleteBackward() }
    func advanceToNextKeyboard() { controller?.advanceToNextInputMode() }
}
