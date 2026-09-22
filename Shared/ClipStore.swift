import Foundation
import Observation

/// Single source of truth for clips. Every mutation is written to disk immediately
/// and announced with a Darwin notification so the other processes can reload.
@MainActor
@Observable
final class ClipStore {
    static let maxHistory = 10

    private(set) var items: [ClipItem] = []
    private(set) var lastError: String?

    private let storage: ClipFileStorage
    private let postsNotifications: Bool

    init(storage: ClipFileStorage = ClipFileStorage(), postsNotifications: Bool = true) {
        self.storage = storage
        self.postsNotifications = postsNotifications
        load()
    }

    // MARK: - Derived views

    /// Pinned clips in the user's manual order.
    var pinned: [ClipItem] {
        items.filter(\.isPinned).sorted {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.createdAt > $1.createdAt
        }
    }

    /// The most recent unpinned clips, newest first, at most `maxHistory`.
    var history: [ClipItem] {
        Array(items.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }.prefix(Self.maxHistory))
    }

    var isEmpty: Bool { items.isEmpty }

    func item(withID id: ClipItem.ID) -> ClipItem? {
        items.first { $0.id == id }
    }

    // MARK: - Loading

    func load() {
        do {
            items = try storage.read().items
            lastError = nil
        } catch {
            lastError = "Could not read clips: \(error.localizedDescription)"
        }
    }

    /// Re-read from disk after another process may have changed the file.
    func reload() { load() }

    // MARK: - Mutations

    /// Records a copied string, optionally pinning it. Returns `true` if the list changed.
    @discardableResult
    func record(_ raw: String, pinned: Bool = false) -> Bool {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }

        let id: ClipItem.ID
        var changed = true
        if let index = items.firstIndex(where: { $0.text == text }) {
            id = items[index].id
            if items[index].isPinned {
                changed = false
            } else {
                items[index].createdAt = Date()
            }
        } else {
            let item = ClipItem(text: text)
            items.append(item)
            id = item.id
        }

        if pinned, let existing = item(withID: id), !existing.isPinned {
            pin(id)
            return true
        }
        guard changed else { return false }
        enforceHistoryCap()
        save()
        return true
    }

    /// Pins a clip and places it at the top of the pinned list.
    func pin(_ id: ClipItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }), !items[index].isPinned else { return }
        for i in items.indices where items[i].isPinned {
            items[i].sortOrder += 1
        }
        items[index].isPinned = true
        items[index].sortOrder = 0
        save()
    }

    /// Unpins a clip; it re-enters history as the newest item.
    func unpin(_ id: ClipItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].isPinned else { return }
        items[index].isPinned = false
        items[index].sortOrder = 0
        items[index].createdAt = Date()
        renumberPinned()
        enforceHistoryCap()
        save()
    }

    func togglePin(_ id: ClipItem.ID) {
        guard let item = item(withID: id) else { return }
        item.isPinned ? unpin(id) : pin(id)
    }

    /// Reorders pinned clips using SwiftUI's `onMove` semantics.
    func movePinned(fromOffsets source: IndexSet, toOffset destination: Int) {
        var ordered = pinned
        ordered.move(fromOffsets: source, toOffset: destination)
        apply(pinnedOrder: ordered)
        save()
    }

    func delete(_ id: ClipItem.ID) {
        guard items.contains(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
        renumberPinned()
        save()
    }

    /// Removes every unpinned clip. Pins are untouched.
    func clearHistory() {
        let before = items.count
        items.removeAll { !$0.isPinned }
        if items.count != before { save() }
    }

    // MARK: - Internals

    private func enforceHistoryCap() {
        let overflow = items
            .filter { !$0.isPinned }
            .sorted { $0.createdAt > $1.createdAt }
            .dropFirst(Self.maxHistory)
            .map(\.id)
        guard !overflow.isEmpty else { return }
        let doomed = Set(overflow)
        items.removeAll { doomed.contains($0.id) }
    }

    private func renumberPinned() {
        apply(pinnedOrder: pinned)
    }

    private func apply(pinnedOrder ordered: [ClipItem]) {
        for (position, item) in ordered.enumerated() {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].sortOrder = position
            }
        }
    }

    private func save() {
        do {
            try storage.write(ClipFile(items: items))
            lastError = nil
            if postsNotifications {
                DarwinNotifier.post(AppGroup.storeDidChangeNotification)
            }
        } catch {
            lastError = "Could not save clips: \(error.localizedDescription)"
        }
    }
}
