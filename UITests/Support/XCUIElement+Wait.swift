import XCTest

private let timeout: TimeInterval = 10

extension XCUIElement {
    var stringValue: String? { value as? String }

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
            wait(for: keyPath, toEqual: expected, timeout: timeout),
            "\(description) never had \(expected), has \(exists ? "\(self[keyPath: keyPath])" : "missing")",
            file: file, line: line)
        return self
    }

    @discardableResult
    func waitUntil<Value>(
        _ keyPath: KeyPath<XCUIElement, Value>, satisfies condition: @escaping (Value) -> Bool,
        file: StaticString = #filePath, line: UInt = #line
    ) -> XCUIElement {
        let predicate = NSPredicate { object, _ in
            guard let element = object as? XCUIElement, element.exists else {
                return false
            }
            return condition(element[keyPath: keyPath])
        }
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: self)], timeout: timeout)
        XCTAssertEqual(
            result, .completed,
            "\(description) never satisfied the condition, has \(exists ? "\(self[keyPath: keyPath])" : "missing")",
            file: file, line: line)
        return self
    }
}
