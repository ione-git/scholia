import XCTest

struct HighlightMenuScreen: Screen {
    static let colors = ["yellow", "green", "blue", "pink", "purple"]

    let app: XCUIApplication

    var root: XCUIElement { app.otherElements["reader.highlightMenu"] }
    var deleteButton: XCUIElement { app.buttons["reader.highlightMenu.delete"] }

    func swatch(_ color: String) -> XCUIElement { app.buttons["reader.highlightMenu.\(color)"] }

    func choose(_ color: String) {
        swatch(color).waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
    }

    func delete() {
        deleteButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
    }
}
