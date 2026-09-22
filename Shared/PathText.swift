import SwiftUI

/// Renders "Settings > General > Keyboard" with iOS-style chevrons between the steps.
/// Write paths with " > " in source; this swaps each separator for a small chevron.
func pathText(_ string: String) -> Text {
    let chevron = Text(Image(systemName: "chevron.right"))
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.tertiary)
    let parts = string.components(separatedBy: " > ")
    return parts.enumerated().reduce(Text("")) { result, entry in
        let (index, part) = entry
        let piece = Text(part)
        return index == 0 ? piece : result + Text(" ") + chevron + Text(" ") + piece
    }
}
