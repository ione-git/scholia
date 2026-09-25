import XCTest

private let timeout: TimeInterval = 10

extension XCUIElement {
    @discardableResult
    func waitUntilExists(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(waitForExistence(timeout: timeout), "\(description) did not appear", file: file, line: line)
        return self
    }

    func waitUntilGone(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            waitForNonExistence(timeout: timeout), "\(description) did not disappear", file: file, line: line)
    }

    @discardableResult
    func waitUntil<Value: Equatable>(
        _ keyPath: KeyPath<XCUIElement, Value>, equals expected: Value, file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            wait(for: keyPath, toEqual: expected, timeout: timeout), "\(description) never had \(expected)", file: file,
            line: line)
        return self
    }
}
