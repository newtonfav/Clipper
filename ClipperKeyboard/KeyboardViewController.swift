import SwiftUI
import UIKit

/// Entry point of the keyboard extension. Hosts the SwiftUI keyboard and owns the
/// height constraint, the store, and the capture-on-open behaviour.
final class KeyboardViewController: UIInputViewController {
    private var store: ClipStore?
    private var actions: KeyboardActions?
    private var hostingController: UIHostingController<KeyboardRootView>?
    private var heightConstraint: NSLayoutConstraint?
    private var clipboardWatcher: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let store = ClipStore()
        let actions = KeyboardActions(controller: self)
        let host = UIHostingController(rootView: KeyboardRootView(store: store, actions: actions))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        // The keyboard container reports a safe area; ignore it so content starts at the top edge.
        host.safeAreaRegions = []

        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)

        self.store = store
        self.actions = actions
        self.hostingController = host

        registerForTraitChanges([UITraitVerticalSizeClass.self, UITraitUserInterfaceStyle.self]) {
            (controller: Self, _) in
            controller.updateHeight()
            controller.actions?.refresh()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeight()
        actions?.refresh()
        store?.reload()
        captureIfNeeded()
        startWatchingClipboard()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clipboardWatcher?.cancel()
        clipboardWatcher = nil
    }

    /// Reads the clipboard if its change count moved. Cheap when nothing changed.
    private func captureIfNeeded() {
        guard hasFullAccess, AppSettings.captureOnKeyboardOpen, let store else { return }
        if ClipboardCapture.captureIfNeeded(into: store) == .recorded {
            actions?.noteCapture()
        }
    }

    /// While the keyboard is on screen the user can copy from the field above it,
    /// so poll the change counter about once a second. Only the counter is read
    /// unless it moved, so this never shows the paste prompt on its own.
    private func startWatchingClipboard() {
        clipboardWatcher?.cancel()
        clipboardWatcher = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.captureIfNeeded()
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in self.updateHeight() }
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        actions?.refresh()
    }

    private func updateHeight() {
        let compact = traitCollection.verticalSizeClass == .compact
        let height: CGFloat = compact ? 200 : 290
        if let heightConstraint {
            heightConstraint.constant = height
        } else {
            let constraint = view.heightAnchor.constraint(equalToConstant: height)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
    }
}
