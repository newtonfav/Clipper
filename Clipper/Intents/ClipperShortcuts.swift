import AppIntents

struct ClipperShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveToClipperIntent(),
            phrases: [
                "Save to \(.applicationName)",
                "Save this to \(.applicationName)",
            ],
            shortTitle: "Save to Clipper",
            systemImageName: "doc.on.clipboard"
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
