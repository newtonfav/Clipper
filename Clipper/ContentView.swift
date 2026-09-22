import SwiftUI
import UIKit

struct ContentView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case pinned = "Pinned"
        var id: String { rawValue }
    }

    @Environment(ClipStore.self) private var store
    @Environment(ProStore.self) private var pro
    @State private var showPaywall = false
    @State private var tab: Tab = .recent
    @State private var showSettings = false
    @State private var showOnboarding = !AppSettings.hasSeenOnboarding
    @State private var confirmClear = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if store.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Clipper")
            .toolbar { toolbar }
            .overlay(alignment: .bottom) { toastView }
            .confirmationDialog("Clear all recent clips?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { store.clearHistory() }
            } message: {
                Text("Pinned clips are kept.")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
            .sheet(isPresented: $showOnboarding) {
                NavigationStack {
                    OnboardingView(onDone: {
                        AppSettings.hasSeenOnboarding = true
                        showOnboarding = false
                    })
                }
            }
        }
    }

    // MARK: - List

    private var visibleItems: [ClipItem] {
        tab == .recent ? store.history : store.pinned
    }

    private var list: some View {
        List {
            Section {
                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if visibleItems.isEmpty {
                Section {
                    tabEmptyState
                        .listRowBackground(Color.clear)
                }
            } else if tab == .pinned {
                Section {
                    ForEach(store.pinned) { item in
                        row(item)
                    }
                    .onMove { store.movePinned(fromOffsets: $0, toOffset: $1) }
                } footer: {
                    if let max = store.limits.maxPins {
                        Text("\(store.pinned.count) of \(max) pins used. Clipper Pro removes the limit.")
                    } else {
                        Text("Drag to reorder. Pinned clips are never removed automatically.")
                    }
                }
            } else {
                Section {
                    ForEach(store.history) { item in
                        row(item)
                    }
                } footer: {
                    Text("The newest \(store.limits.maxHistory) copies are kept. Pin one to keep it.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.snappy(duration: 0.25), value: visibleItems.map(\.id))
        .onChange(of: tab) { _, _ in
            toastTask?.cancel()
            toast = nil
        }
    }

    private func row(_ item: ClipItem) -> some View {
        ClipRowView(item: item, actionsEnabled: store.limits.kindActions, onCopy: { copy(item) }, onLocked: { showPaywall = true })
            .contentShape(Rectangle())
            .onTapGesture { copy(item) }
            .contextMenu {
                Button {
                    copy(item)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Button {
                    togglePin(item)
                } label: {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                Divider()
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    togglePin(item)
                } label: {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: - Empty states

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No clips yet", systemImage: "doc.on.clipboard")
        } description: {
            Text("Copy text anywhere, then come back here or open the Clipper keyboard. Or paste something now with the button above.")
        } actions: {
            Button("Setup guide") { showOnboarding = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var tabEmptyState: some View {
        ContentUnavailableView {
            Label(tab == .recent ? "No recent clips" : "No pinned clips",
                  systemImage: tab == .recent ? "clock" : "pin")
        } description: {
            Text(tab == .recent
                 ? "New copies show up here."
                 : "Swipe right or long-press a recent clip to pin it.")
        }
        .padding(.vertical, 24)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if tab == .pinned, !store.pinned.isEmpty {
                EditButton()
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            PasteButton(payloadType: String.self) { strings in
                MainActor.assumeIsolated {
                    if store.record(strings.joined(separator: "\n")) {
                        tab = .recent
                        showToast("Saved")
                    }
                }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
            Menu {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                Button {
                    showOnboarding = true
                } label: {
                    Label("Setup guide", systemImage: "keyboard")
                }
                Divider()
                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(store.history.isEmpty)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Actions

    private func togglePin(_ item: ClipItem) {
        let wasPinned = item.isPinned
        if store.togglePin(item.id) {
            showToast(wasPinned ? "Unpinned" : "Pinned")
        } else {
            showPaywall = true
        }
    }

    private func delete(_ item: ClipItem) {
        store.delete(item.id)
        showToast("Deleted")
    }

    private func copy(_ item: ClipItem) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = item.text
        // Our own write must not be re-recorded on the next foreground.
        AppGroup.defaults.set(pasteboard.changeCount, forKey: AppGroup.DefaultsKey.lastSeenChangeCount)
        showToast("Copied")
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.snappy) { toast = message }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { toast = nil }
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    ContentView()
        .environment(ClipStore(storage: ClipFileStorage(directory: FileManager.default.temporaryDirectory), postsNotifications: false))
}
