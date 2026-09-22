import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// "Save to Clipper" in the share sheet. Accepts plain text or a single web URL.
final class ShareViewController: UIViewController {
    private let model = ShareModel()
    private lazy var store = ClipStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        let root = ShareSheetView(
            model: model,
            onSave: { [weak self] pin in self?.save(pin: pin) },
            onCancel: { [weak self] in self?.cancel() }
        )
        let host = UIHostingController(rootView: root)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)

        loadSharedContent()
    }

    // MARK: - Input

    private func loadSharedContent() {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        let fallback = items.compactMap { $0.attributedContentText?.string }.first

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] data, _ in
                let text = (data as? String) ?? (data as? Data).flatMap { String(data: $0, encoding: .utf8) }
                Task { @MainActor in self?.model.finishLoading(text ?? fallback) }
            }
        } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, _ in
                let text = (data as? URL)?.absoluteString
                Task { @MainActor in self?.model.finishLoading(text ?? fallback) }
            }
        } else {
            model.finishLoading(fallback)
        }
    }

    // MARK: - Output

    private func save(pin: Bool) {
        store.record(model.text, pinned: pin)
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
    }
}
