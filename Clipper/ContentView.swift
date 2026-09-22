import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(ClipStore.self) private var store
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

    // MARK: - Sections

    private var list: some View {
        List {
            if !store.pinned.isEmpty {
                Section("Pinned") {
                    ForEach(store.pinned) { item in
                        row(item)
                    }
                    .onMove { store.movePinned(fromOffsets: $0, toOffset: $1) }
                }
            }
            Section {
                ForEach(store.history) { item in
                    row(item)
                }
            } header: {
                Text("Recent")
            } footer: {
                if store.history.isEmpty {
                    Text("Recent copies show up here. The newest \(ClipStore.maxHistory) are kept.")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(_ item: ClipItem) -> some View {
        ClipRowView(item: item, onCopy: { copy(item) })
            .contentShape(Rectangle())
            .onTapGesture { copy(item) }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    store.togglePin(item.id)
                } label: {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    store.delete(item.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

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

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !store.pinned.isEmpty {
                EditButton()
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            PasteButton(payloadType: String.self) { strings in
                MainActor.assumeIsolated {
                    if store.record(strings.joined(separator: "\n")) {
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
