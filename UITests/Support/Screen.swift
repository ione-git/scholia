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

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        root.waitUntilExists(file: file, line: line)
        return self
    }
}
