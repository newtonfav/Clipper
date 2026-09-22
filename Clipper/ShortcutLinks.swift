import Foundation

/// Pre-built shortcuts the user can install with one tap.
///
/// iOS only imports shortcuts signed by Apple, so an app cannot generate one. The
/// supported route is an iCloud link created once by the developer:
///  1. On an iPhone with Clipper installed, open Shortcuts and create a new shortcut.
///  2. Add "Get Clipboard", then add "Save to Clipper" and set its Text to the Clipboard variable.
///  3. Name it "Save to Clipper", tap Share, then Copy iCloud Link.
///  4. Paste the link below and rebuild.
/// Until a link is set, the setup guide shows the manual recipe instead.
enum ShortcutLinks {
    /// Get Clipboard → Save to Clipper. Silent, runs in the background, ideal for Back Tap.
    static let saveClipboardShortcut: URL? = URL(string: "https://www.icloud.com/shortcuts/df82eb04ff264350a83a0d85468d4ae3")
}


