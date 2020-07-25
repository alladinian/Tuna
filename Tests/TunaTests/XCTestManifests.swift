import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TunaTests.allTests),
        testCase(PitchyTests.allTests)
    ]
}
#endif
