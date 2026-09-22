import SwiftUI

struct KeyboardRootView: View {
    var store: ClipStore
    var actions: KeyboardActions

    @State private var expandedID: ClipItem.ID?
    @State private var isEditing = false
    @State private var deleteRepeater: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            if !actions.hasFullAccess {
                fullAccessBanner
            }
            content
            bottomBar
        }
        .preferredColorScheme(actions.isDarkAppearance ? .dark : nil)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Label("Clipper", systemImage: "doc.on.clipboard")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if !store.isEmpty, actions.hasFullAccess {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                    expandedID = nil
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var fullAccessBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock")
            Text("Turn on Allow Full Access to capture copies and pin from here. Settings › General › Keyboard › Keyboards › Clipper.")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "clipboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Nothing saved yet")
                    .font(.subheadline.weight(.semibold))
                Text("Copy text in any app, then open this keyboard or the Clipper app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6, pinnedViews: []) {
                    section("Pinned", items: store.pinned)
                    section("Recent", items: store.history)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, items: [ClipItem]) -> some View {
        if !items.isEmpty {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            ForEach(items) { item in
                ClipChipRow(
                    item: item,
                    isExpanded: expandedID == item.id,
                    isEditing: isEditing,
                    canModify: actions.hasFullAccess,
                    onInsert: { text in
                        expandedID = nil
                        actions.insert(text)
                    },
                    onToggleExpand: {
                        expandedID = expandedID == item.id ? nil : item.id
                    },
                    onTogglePin: { store.togglePin(item.id) },
                    onDelete: { store.delete(item.id) }
                )
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 8) {
            if actions.needsInputModeSwitchKey {
                NextKeyboardButton(controller: actions.inputViewController)
                    .frame(width: 44, height: 40)
                    .background(KeyboardTheme.specialKeyColor, in: RoundedRectangle(cornerRadius: 8))
            }

            key(label: "space", isText: true) { actions.insertSpace() }
                .frame(maxWidth: .infinity)

            key(label: "return", isText: true) { actions.insertNewline() }
                .frame(width: 80)

            key(label: "delete.left", isText: false) { actions.deleteBackward() }
                .frame(width: 52)
                .onLongPressGesture(minimumDuration: 0.4, maximumDistance: 30) {
                    // handled in onPressingChanged
                } onPressingChanged: { pressing in
                    if pressing {
                        startDeleteRepeat()
                    } else {
                        deleteRepeater?.cancel()
                        deleteRepeater = nil
                    }
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func key(label: String, isText: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if isText {
                    Text(label).font(.subheadline)
                } else {
                    Image(systemName: label).font(.body)
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(KeyboardTheme.specialKeyColor, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func startDeleteRepeat() {
        deleteRepeater?.cancel()
        deleteRepeater = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            while !Task.isCancelled {
                actions.deleteBackward()
                try? await Task.sleep(for: .milliseconds(70))
            }
        }
    }
}
