import AppIntents

struct ClipperShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveClipboardIntent(),
            phrases: [
                "Save my clipboard to \(.applicationName)",
                "Save clipboard with \(.applicationName)",
            ],
            shortTitle: "Save Clipboard",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: SaveToClipperIntent(),
            phrases: [
                "Save to \(.applicationName)",
                "Save this to \(.applicationName)",
            ],
            shortTitle: "Save Text",
            systemImageName: "text.badge.plus"
        )
        AppShortcut(
            intent: GetClipperItemsIntent(),
            phrases: [
                "Show my \(.applicationName) clips",
                "Get my \(.applicationName) clips",
            ],
            shortTitle: "Get Clips",
            systemImageName: "list.bullet.rectangle"
        )
    }
}
