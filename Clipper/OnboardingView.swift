import SwiftUI
import UIKit

/// Three short steps. Shown as a sheet on first launch (`onDone` set) and from Settings (`onDone` nil).
struct OnboardingView: View {
    var onDone: (() -> Void)?
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                step(
                    number: 1,
                    title: "Turn on the keyboard",
                    detail: "Go to Settings > General > Keyboard > Keyboards, tap Add New Keyboard and pick Clipper. Then tap Clipper and turn on Allow Full Access.",
                    symbol: "keyboard"
                )
                Button {
                    open(UIApplication.openSettingsURLString)
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
            }

            Section {
                step(
                    number: 2,
                    title: "Let Clipper read your clipboard",
                    detail: "The first time Clipper reads a copy, iOS shows a “Clipper would like to paste” alert. Tap Allow Paste. To stop the alert for good, go to Settings > Clipper and set Paste from Other Apps to Allow.",
                    symbol: "doc.on.clipboard"
                )
            }

            Section {
                step(
                    number: 3,
                    title: "Save with one tap",
                    detail: "Add the shortcut, then choose it in Settings > Accessibility > Touch > Back Tap. With an Action Button, pick Clipper's Save Clipboard in Settings > Action Button.",
                    symbol: "hand.tap"
                )
                if let link = ShortcutLinks.saveClipboardShortcut {
                    Button {
                        openURL(link)
                    } label: {
                        Label("Add Shortcut", systemImage: "plus.square.on.square")
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    GlobeKeyHintView()
                    Text("In any app, hold the globe key on the keyboard and pick Clipper. Tap a clip to insert it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Using it")
            } footer: {
                Text("Everything stays on this device.")
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

    private func step(number: Int, title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(number). \(title)")
                    .font(.headline)
                pathText(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func open(_ string: String) {
        if let url = URL(string: string) { openURL(url) }
    }
}
