import Foundation
import Observation

/// Single source of truth for clips. Every mutation is written to disk immediately
/// and announced with a Darwin notification so the other processes can reload.
@MainActor
@Observable
final class ClipStore {
    private(set) var items: [ClipItem] = []
    private(set) var lastError: String?
    private(set) var limits: Limits

    private let storage: ClipFileStorage
    private let postsNotifications: Bool
    private let fixedLimits: Limits?

    /// - Parameter limits: pass explicit limits (tests); otherwise the current tier's.
    init(storage: ClipFileStorage = ClipFileStorage(), postsNotifications: Bool = true, limits: Limits? = nil) {
        self.storage = storage
        self.postsNotifications = postsNotifications
        self.fixedLimits = limits
        self.limits = limits ?? Entitlements.limits
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

    /// The most recent unpinned clips, newest first, at most `limits.maxHistory`.
    var history: [ClipItem] {
        Array(items.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }.prefix(limits.maxHistory))
    }

    var isEmpty: Bool { items.isEmpty }

    /// Whether one more clip may be pinned under the current tier.
    var canPinMore: Bool {
        guard let max = limits.maxPins else { return true }
        return pinned.count < max
    }

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

    /// Re-read from disk after another process may have changed the file or the tier.
    func reload() {
        refreshLimits()
        load()
    }

    /// Picks up a tier change (purchase, restore, refund).
    func refreshLimits() {
        limits = fixedLimits ?? Entitlements.limits
    }

    // MARK: - Mutations

    /// Records a copied string, optionally pinning it. Returns `true` if the list changed.
    /// If pinning is requested but the pin limit is reached, the clip is saved unpinned.
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

        if pinned, let existing = item(withID: id), !existing.isPinned, canPinMore {
            pin(id)
            return true
        }
        guard changed else { return false }
        enforceHistoryCap()
        save()
        return true
    }

    /// Pins a clip and places it at the top of the pinned list.
    /// Returns `false` when the tier's pin limit is reached; nothing changes then.
    @discardableResult
    func pin(_ id: ClipItem.ID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }), !items[index].isPinned else { return false }
        guard canPinMore else { return false }
        for i in items.indices where items[i].isPinned {
            items[i].sortOrder += 1
        }
        items[index].isPinned = true
        items[index].sortOrder = 0
        save()
        return true
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

    /// Returns `false` only when a pin was refused because of the limit.
    @discardableResult
    func togglePin(_ id: ClipItem.ID) -> Bool {
        guard let item = item(withID: id) else { return false }
        if item.isPinned {
            unpin(id)
            return true
        }
        return pin(id)
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
            .dropFirst(limits.maxHistory)
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
