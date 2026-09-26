import XCTest

struct ReaderSettingsScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["readerSettings.sheet"] }
    var smaller: XCUIElement { app.buttons["readerSettings.smaller"] }
    var larger: XCUIElement { app.buttons["readerSettings.larger"] }
    var size: XCUIElement { app.sliders["readerSettings.size"] }
    var lockRotation: XCUIElement { app.switches["readerSettings.lockRotation"] }

    func theme(_ name: String) -> XCUIElement { app.buttons["readerSettings.theme.\(name)"] }
    func font(_ name: String) -> XCUIElement { app.buttons["readerSettings.font.\(name)"] }
    func pageTurn(_ name: String) -> XCUIElement { app.buttons["readerSettings.pageTurn.\(name)"] }
    func lineSpacing(_ name: String) -> XCUIElement { app.buttons["readerSettings.lineSpacing.\(name)"] }

    func choose(_ option: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        option.waitUntilExists(file: file, line: line).tap()
        option.waitUntil(\.isSelected, equals: true, file: file, line: line)
    }

    func step(_ button: XCUIElement, expecting value: String, file: StaticString = #filePath, line: UInt = #line) {
        button.waitUntil(\.isEnabled, equals: true, file: file, line: line).tap()
        size.waitUntil(\.stringValue, equals: value, file: file, line: line)
    }

    func slideSize(to position: CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        let steps = (size.waitUntilExists(file: file, line: line).stringValue ?? "").components(separatedBy: " of ")
            .compactMap { Int($0) }
        let thumb = CGFloat(steps[0] - 1) / CGFloat(steps[1] - 1)
        size.coordinate(withNormalizedOffset: CGVector(dx: thumb, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: size.coordinate(withNormalizedOffset: CGVector(dx: position, dy: 0.5)))
    }

    func setLockRotation(_ isOn: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let value = isOn ? "1" : "0"
        guard lockRotation.waitUntilExists(file: file, line: line).stringValue != value else {
            return
        }
        lockRotation.tap()
        lockRotation.waitUntil(\.stringValue, equals: value, file: file, line: line)
    }

    func closeByTappingPage(_ reader: ReaderScreen) {
        reader.root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        root.waitUntilGone()
    }
}
