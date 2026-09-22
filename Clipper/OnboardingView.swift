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
                    title: "Allow pasting",
                    detail: "In Settings > Clipper, set Paste from Other Apps to Allow. Until then, tap Allow Paste when iOS asks.",
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
            } footer: {
                Text("Then hold the globe key in any app and pick Clipper. Everything stays on this device.")
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
