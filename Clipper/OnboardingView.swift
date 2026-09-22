import SwiftUI
import UIKit

/// Walks the user through the iOS settings Clipper depends on.
/// Shown as a sheet on first launch (`onDone` set) and from Settings (`onDone` nil).
struct OnboardingView: View {
    var onDone: (() -> Void)?
    @Environment(\.openURL) private var openURL
    @State private var scratch = ""

    private struct Step: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let symbol: String
    }

    private let steps: [Step] = [
        Step(
            title: "Add the keyboard",
            detail: "Settings › General › Keyboard › Keyboards › Add New Keyboard › Clipper.",
            symbol: "keyboard"
        ),
        Step(
            title: "Allow Full Access",
            detail: "In the same Keyboards list tap Clipper and turn on Allow Full Access. The keyboard needs it to read your clipboard and to pin items. iOS may close this app the first time; just reopen it.",
            symbol: "lock.open"
        ),
        Step(
            title: "Stop the paste prompt",
            detail: "After the first “would like to paste” alert, go to Settings › Apps › Clipper › Paste from Other Apps and choose Allow.",
            symbol: "doc.on.clipboard"
        ),
        Step(
            title: "Keep Clipper last",
            detail: "Order the Keyboards list so Clipper is at the bottom. After inserting, Clipper switches to the next keyboard, which is then your usual one.",
            symbol: "arrow.uturn.backward"
        ),
        Step(
            title: "Save with one tap",
            detail: "In Shortcuts create a shortcut: Get Clipboard → Save to Clipper. Then bind it under Settings › Accessibility › Touch › Back Tap, or to the Action Button. Copy, double-tap the back of your phone, done.",
            symbol: "hand.tap"
        ),
        Step(
            title: "Use it",
            detail: "In any app hold the globe key and pick Clipper. Tap a clip to insert it, long-press for variants, tap the pin to keep it forever. Or share text to Clipper from the share sheet.",
            symbol: "sparkles"
        ),
    ]

    var body: some View {
        List {
            Section {
                Text("Clipper keeps your last \(ClipStore.maxHistory) copies and anything you pin, entirely on this device. iOS only lets it see the clipboard at a few moments, so a short setup makes it work everywhere.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: step.symbol)
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(index + 1). \(step.title)")
                                .font(.headline)
                            Text(step.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            Section {
                TextField("Tap here, hold the globe key and pick Clipper", text: $scratch, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Try it")
            } footer: {
                Text("Nothing typed here is saved.")
            }
            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Label("Open Clipper in Settings", systemImage: "gear")
                }
                Button {
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                } label: {
                    Label("Open Shortcuts", systemImage: "square.2.layers.3d")
                }
            } footer: {
                Text("iOS has no direct link to the Keyboards screen; from the Clipper page go back to Settings › General › Keyboard.")
            }
        }
        .navigationTitle("Set up Clipper")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onDone {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
    }
}
