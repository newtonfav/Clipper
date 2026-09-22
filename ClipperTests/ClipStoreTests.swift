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

    private func makeStore() -> ClipStore {
        ClipStore(storage: ClipFileStorage(directory: directory), postsNotifications: false)
    }

    func testRecordKeepsNewestTenUnpinned() {
        let store = makeStore()
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
        let store = makeStore()
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
