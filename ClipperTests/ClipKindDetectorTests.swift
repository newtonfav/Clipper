import XCTest
@testable import Clipper

final class ClipKindDetectorTests: XCTestCase {
    func testLinks() {
        XCTAssertEqual(ClipKindDetector.detect("https://example.com/path?q=1"), .link)
        XCTAssertEqual(ClipKindDetector.detect("http://example.com"), .link)
        XCTAssertEqual(ClipKindDetector.detect("  https://example.com  "), .link)
    }

    func testEmails() {
        XCTAssertEqual(ClipKindDetector.detect("someone@example.com"), .email)
        XCTAssertEqual(ClipKindDetector.detect("mailto:someone@example.com"), .email)
    }

    func testPhones() {
        XCTAssertEqual(ClipKindDetector.detect("+1 (555) 123-4567"), .phone)
        XCTAssertEqual(ClipKindDetector.detect("555-123-4567"), .phone)
    }

    func testCodes() {
        XCTAssertEqual(ClipKindDetector.detect("123456"), .code)
        XCTAssertEqual(ClipKindDetector.detect("123 456"), .code)
        XCTAssertEqual(ClipKindDetector.detect("1234-5678"), .code)
        XCTAssertEqual(ClipKindDetector.detect("1234"), .code)
    }

    func testPlainText() {
        XCTAssertEqual(ClipKindDetector.detect("Meet me at https://example.com later"), .text)
        XCTAssertEqual(ClipKindDetector.detect("hello world"), .text)
        XCTAssertEqual(ClipKindDetector.detect("123"), .text)
        XCTAssertEqual(ClipKindDetector.detect("12345678a"), .text)
        XCTAssertEqual(ClipKindDetector.detect(""), .text)
    }
}
