import XCTest

struct SelectionMenuScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.otherElements["reader.selectionMenu"] }
    var highlightItem: XCUIElement { app.buttons["reader.selectionMenu.highlight"] }
    var translateItem: XCUIElement { app.buttons["reader.selectionMenu.translate"] }
    var copyItem: XCUIElement { app.buttons["reader.selectionMenu.copy"] }

    func highlight() {
        choose(highlightItem)
    }

    func translate() {
        choose(translateItem)
    }

    func copy() {
        choose(copyItem)
    }

    private func choose(_ item: XCUIElement) {
        item.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
    }
}
