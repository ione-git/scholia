import XCTest

struct NewCollectionAlert: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.alerts.firstMatch }

    var nameField: XCUIElement { root.textFields.firstMatch }
    var createButton: XCUIElement { root.buttons["newCollection.create"].firstMatch }
    var cancelButton: XCUIElement { root.buttons["newCollection.cancel"].firstMatch }

    @discardableResult
    func type(_ name: String) -> Self {
        let field = nameField.waitUntil(\.isHittable, equals: true)
        field.tap()
        let current = field.stringValue ?? ""
        let count = current == field.placeholderValue ? 0 : current.count
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count) + name)
        return self
    }

    @discardableResult
    func create<Next: Screen>(returningTo next: Next) -> Next {
        createButton.waitUntil(\.isEnabled, equals: true).tap()
        root.waitUntilGone()
        return next.waitUntilShown()
    }

    @discardableResult
    func cancel<Next: Screen>(returningTo next: Next) -> Next {
        cancelButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return next.waitUntilShown()
    }
}
