import XCTest
@testable import Clipper

final class TextTransformTests: XCTestCase {
    let sample = "  Hello   World \n\n second line \n"

    func testTrimmed() {
        XCTAssertEqual(TextTransform.trimmed.apply(to: sample), "Hello World second line")
    }

    func testUppercase() {
        XCTAssertEqual(TextTransform.uppercase.apply(to: "abc Déf"), "ABC DÉF")
    }

    func testLowercase() {
        XCTAssertEqual(TextTransform.lowercase.apply(to: "ABC Déf"), "abc déf")
    }

    func testFirstLine() {
        XCTAssertEqual(TextTransform.firstLine.apply(to: sample), "Hello   World")
        XCTAssertEqual(TextTransform.firstLine.apply(to: "\n\n"), "")
    }
}
