import XCTest

@MainActor
protocol Screen {
    var app: XCUIApplication { get }
    var root: XCUIElement { get }
}

extension Screen {
    var launchConfiguration: XCUIElement {
        app.descendants(matching: .any)["debug.launchConfiguration"]
    }

    var storedLibrary: XCUIElement {
        app.descendants(matching: .any)["debug.storedLibrary"]
    }

    var storedHighlights: XCUIElement {
        app.descendants(matching: .any)["debug.storedHighlights"]
    }

    var pasteboard: XCUIElement {
        app.descendants(matching: .any)["debug.pasteboard"]
    }

    var readingReminder: XCUIElement {
        app.descendants(matching: .any)["debug.readingReminder"]
    }

    var privacyManifest: XCUIElement {
        app.descendants(matching: .any)["debug.privacyManifest"]
    }

    var colorScheme: XCUIElement {
        app.descendants(matching: .any)["debug.colorScheme"]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        root.waitUntilExists(file: file, line: line)
        return self
    }

    @discardableResult
    func waitUntil<Value: Equatable>(
        _ keyPath: KeyPath<Self, Value>, equals expected: Value, file: StaticString = #filePath, line: UInt = #line
    ) -> Self {
        let predicate = NSPredicate { _, _ in
            MainActor.assumeIsolated { self[keyPath: keyPath] == expected }
        }
        let result = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: timeout)
        XCTAssertEqual(
            result, .completed, "\(Self.self) never had \(expected), has \(self[keyPath: keyPath])", file: file,
            line: line)
        return self
    }

    func elements(identifiedBy prefix: String) -> [any XCUIElementSnapshot]? {
        guard let root = try? app.snapshot() else { return nil }
        var found: [any XCUIElementSnapshot] = []
        var pending = [root]
        while let element = pending.popLast() {
            if element.identifier.hasPrefix(prefix) {
                found.append(element)
            }
            pending.append(contentsOf: element.children)
        }
        return found
    }

    @discardableResult
    func waitUntilSettled(file: StaticString = #filePath, line: UInt = #line) -> Self {
        root.waitUntil(\.frame, equals: app.frame, file: file, line: line)
        return self
    }
}
