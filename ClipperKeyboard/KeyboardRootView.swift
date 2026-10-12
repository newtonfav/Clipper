import SwiftUI

struct KeyboardRootView: View {
    var store: ClipStore
    var actions: KeyboardActions

    private enum Tab: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case pinned = "Pinned"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .recent
    @State private var expandedID: ClipItem.ID?
    @State private var isEditing = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            if !actions.hasFullAccess {
                fullAccessBanner
            }
            if let error = store.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
            ZStack(alignment: .bottom) {
                content
                if let toast {
                    Text(toast)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(actions.isDarkAppearance ? .dark : nil)
        .onChange(of: actions.captureCount) { _, _ in
            tab = .recent
            showToast("Saved to Clipper")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            if actions.needsInputModeSwitchKey {
                NextKeyboardButton(controller: actions.inputViewController)
                    .frame(width: 36, height: 30)
                    .background(KeyboardTheme.specialKeyColor, in: RoundedRectangle(cornerRadius: 7))
            }

            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)

            Spacer()

            if !visibleItems.isEmpty, actions.hasFullAccess {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                    expandedID = nil
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(minHeight: Self.headerMinHeight)
        .onChange(of: tab) { _, _ in
            expandedID = nil
            isEditing = false
        }
    }

    /// On iOS 26 the system shades the top of the Liquid Glass keyboard panel where its
    /// own assistant bar sits (about 44pt, fading out). That shading is drawn over our
    /// content, so the header claims that zone and the first row starts below it.
    private static var headerMinHeight: CGFloat {
        if #available(iOS 26, *) { 52 } else { 0 }
    }

    private var fullAccessBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock")
            pathText("Turn on Allow Full Access to capture copies and pin from here. Settings > General > Keyboard > Keyboards > Clipper.")
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

    private var visibleItems: [ClipItem] {
        tab == .recent ? store.history : store.pinned
    }

    @ViewBuilder
    private var content: some View {
        if visibleItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(visibleItems) { item in
                        ClipChipRow(
                            item: item,
                            isExpanded: expandedID == item.id,
                            isEditing: isEditing,
                            canModify: actions.hasFullAccess,
                            variantsEnabled: store.limits.insertVariants,
                            onInsert: { text in
                                expandedID = nil
                                actions.insert(text)
                            },
                            onToggleExpand: {
                                expandedID = expandedID == item.id ? nil : item.id
                            },
                            onTogglePin: { togglePin(item) },
                            onDelete: { delete(item) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 6)
                .animation(.snappy(duration: 0.25), value: visibleItems.map(\.id))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: tab == .recent ? "clipboard" : "pin")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(tab == .recent ? "Nothing copied yet" : "No pinned clips")
                .font(.subheadline.weight(.semibold))
            Text(tab == .recent
                 ? "Copy text in any app, then open this keyboard or the Clipper app."
                 : "Tap the pin on a recent clip to keep it here for good.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func togglePin(_ item: ClipItem) {
        let wasPinned = item.isPinned
        if store.togglePin(item.id) {
            showToast(wasPinned ? "Unpinned" : "Pinned")
        } else {
            showToast("Pin limit reached. Upgrade in the Clipper app.")
        }
    }

    private func delete(_ item: ClipItem) {
        store.delete(item.id)
        showToast("Deleted")
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.snappy(duration: 0.2)) { toast = message }
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.2)) { toast = nil }
        }
    }
}
