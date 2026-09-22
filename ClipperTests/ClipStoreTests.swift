import XCTest
@testable import Clipper

@MainActor
final class ClipStoreTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore(limits: Limits = .pro) -> ClipStore {
        ClipStore(storage: ClipFileStorage(directory: directory), postsNotifications: false, limits: limits)
    }

    func testFreeTierCapsHistoryAtTen() {
        let store = makeStore(limits: .free)
        for i in 1...12 { store.record("clip \(i)") }
        XCTAssertEqual(store.history.count, 10)
        XCTAssertEqual(store.history.first?.text, "clip 12")
    }

    func testFreeTierRefusesSixthPin() {
        let store = makeStore(limits: .free)
        for i in 1...6 { store.record("clip \(i)") }
        let ids = store.history.map(\.id)
        for id in ids.prefix(5) { XCTAssertTrue(store.pin(id)) }
        XCTAssertFalse(store.canPinMore)
        XCTAssertFalse(store.pin(ids[5]))
        XCTAssertEqual(store.pinned.count, 5)
        XCTAssertEqual(store.history.count, 1)
        XCTAssertFalse(store.togglePin(ids[5]))
    }

    func testRecordWithPinFallsBackToHistoryAtLimit() {
        let store = makeStore(limits: .free)
        for i in 1...5 {
            store.record("pin \(i)", pinned: true)
        }
        XCTAssertEqual(store.pinned.count, 5)
        store.record("one more", pinned: true)
        XCTAssertEqual(store.pinned.count, 5)
        XCTAssertEqual(store.history.first?.text, "one more")
    }

    func testProTierKeepsFiftyRecent() {
        let store = makeStore(limits: .pro)
        for i in 1...60 { store.record("clip \(i)") }
        XCTAssertEqual(store.history.count, 50)
    }

    func testRecordKeepsNewestUnpinnedUpToLimit() {
        let store = makeStore(limits: Limits(maxPins: nil, maxHistory: 10, insertVariants: true, kindActions: true))
        for i in 1...12 { store.record("clip \(i)") }
        XCTAssertEqual(store.history.count, 10)
        XCTAssertEqual(store.history.first?.text, "clip 12")
        XCTAssertEqual(store.history.last?.text, "clip 3")
    }

    func testRecordIgnoresEmptyAndTrims() {
        let store = makeStore()
        XCTAssertFalse(store.record("   \n"))
        XCTAssertTrue(store.record("  hello  "))
        XCTAssertEqual(store.history.first?.text, "hello")
    }

    func testDuplicateMovesToTop() {
        let store = makeStore()
        store.record("a")
        store.record("b")
        store.record("a")
        XCTAssertEqual(store.history.map(\.text), ["a", "b"])
        XCTAssertEqual(store.items.count, 2)
    }

    func testDuplicateOfPinnedIsNoOp() {
        let store = makeStore()
        store.record("keep")
        store.pin(store.history[0].id)
        XCTAssertFalse(store.record("keep"))
        XCTAssertTrue(store.history.isEmpty)
        XCTAssertEqual(store.pinned.count, 1)
    }

    func testPinnedItemsSurviveCap() {
        let store = makeStore(limits: Limits(maxPins: nil, maxHistory: 10, insertVariants: true, kindActions: true))
        store.record("pinned one")
        store.pin(store.history[0].id)
        for i in 1...15 { store.record("clip \(i)") }
        XCTAssertEqual(store.pinned.map(\.text), ["pinned one"])
        XCTAssertEqual(store.history.count, 10)
    }

    func testNewPinLandsOnTopAndUnpinReturnsToHistory() {
        let store = makeStore()
        store.record("first")
        store.record("second")
        let first = store.history.first { $0.text == "first" }!
        let second = store.history.first { $0.text == "second" }!
        store.pin(first.id)
        store.pin(second.id)
        XCTAssertEqual(store.pinned.map(\.text), ["second", "first"])

        store.unpin(second.id)
        XCTAssertEqual(store.pinned.map(\.text), ["first"])
        XCTAssertEqual(store.history.first?.text, "second")
    }

    func testMovePinnedReorders() {
        let store = makeStore()
        for name in ["a", "b", "c"] {
            store.record(name)
            store.pin(store.history[0].id)
        }
        XCTAssertEqual(store.pinned.map(\.text), ["c", "b", "a"])
        store.movePinned(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        XCTAssertEqual(store.pinned.map(\.text), ["a", "c", "b"])

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.pinned.map(\.text), ["a", "c", "b"])
    }

    func testDeleteAndClearHistory() {
        let store = makeStore()
        store.record("gone")
        store.record("stay")
        store.pin(store.history.first { $0.text == "stay" }!.id)
        store.delete(store.history[0].id)
        XCTAssertTrue(store.history.isEmpty)
        store.record("x")
        store.clearHistory()
        XCTAssertTrue(store.history.isEmpty)
        XCTAssertEqual(store.pinned.map(\.text), ["stay"])
    }

    func testPersistsAcrossInstances() {
        let store = makeStore()
        store.record("persisted")
        let again = makeStore()
        XCTAssertEqual(again.history.map(\.text), ["persisted"])
    }
}
