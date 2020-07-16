import XCTest
@testable import Tuna

final class TunaTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Tuna().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
