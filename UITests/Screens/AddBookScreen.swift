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

    func coverColor() throws -> RGBColor {
        try cover.screenshot().color(at: CGPoint(x: 0.5, y: 0.3))
    }

    @discardableResult
    func replaceTitle(with title: String) throws -> Self {
        try replaceText(in: titleField, with: title)
    }

    @discardableResult
    func replaceAuthor(with author: String) throws -> Self {
        try replaceText(in: authorField, with: author)
    }

    func openFromOtherApp(_ fixture: Fixture) throws -> Self {
        XCUIDevice.shared.system.open(try fixture.file)
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

    private func replaceText(in field: XCUIElement, with text: String) throws -> Self {
        let field = field.waitUntil(\.isHittable, equals: true)
        let current = try XCTUnwrap(field.stringValue)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text + "\n")
        return self
    }
}
