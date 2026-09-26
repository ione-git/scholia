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

    var readingReminder: XCUIElement {
        app.descendants(matching: .any)["debug.readingReminder"]
    }

    var privacyManifest: XCUIElement {
        app.descendants(matching: .any)["debug.privacyManifest"]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        root.waitUntilExists(file: file, line: line)
        return self
    }

    @discardableResult
    func waitUntilSettled(file: StaticString = #filePath, line: UInt = #line) -> Self {
        root.waitUntil(\.frame, equals: app.frame, file: file, line: line)
        return self
    }
}
