import XCTest

struct AddBookScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { cancelButton }

    var cancelButton: XCUIElement { app.buttons["addBook.cancel"] }
    var cover: XCUIElement { app.descendants(matching: .any)["addBook.cover"] }
    var fileInfo: XCUIElement { app.staticTexts["addBook.fileInfo"] }
    var titleField: XCUIElement { app.textFields["addBook.title"] }
    var authorField: XCUIElement { app.textFields["addBook.author"] }
    var languageButton: XCUIElement { app.buttons["addBook.language"] }
    var addButton: XCUIElement { app.buttons["addBook.add"] }

    @discardableResult
    func replaceTitle(with title: String) throws -> Self {
        let field = titleField.waitUntil(\.isHittable, equals: true)
        let current = try XCTUnwrap(field.stringValue)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + title + "\n")
        return self
    }

    func chooseLanguage() -> LanguagePickerScreen {
        languageButton.waitUntil(\.isHittable, equals: true).tap()
        return LanguagePickerScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func add() -> HomeScreen {
        addButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func cancel() -> HomeScreen {
        cancelButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }
}
