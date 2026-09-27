import XCTest

struct BookInfoScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { doneButton }

    var cancelButton: XCUIElement { app.buttons["bookInfo.cancel"] }
    var doneButton: XCUIElement { app.buttons["bookInfo.done"] }
    var cover: XCUIElement { app.descendants(matching: .any)["bookInfo.cover"] }
    var fileInfo: XCUIElement { app.staticTexts["bookInfo.fileInfo"] }
    var titleField: XCUIElement { app.textFields["bookInfo.title"] }
    var authorField: XCUIElement { app.textFields["bookInfo.author"] }
    var languageButton: XCUIElement { app.buttons["bookInfo.language"] }
    var collectionsButton: XCUIElement { app.buttons["bookInfo.collections"] }
    var progress: XCUIElement { app.descendants(matching: .any)["bookInfo.progress"] }
    var highlights: XCUIElement { app.descendants(matching: .any)["bookInfo.highlights"] }
    var resetProgressButton: XCUIElement { app.buttons["bookInfo.resetProgress"] }

    @discardableResult
    func replaceTitle(with title: String) throws -> Self {
        try replaceText(in: titleField, with: title)
    }

    @discardableResult
    func replaceAuthor(with author: String) throws -> Self {
        try replaceText(in: authorField, with: author)
    }

    @discardableResult
    func resetProgress() -> Self {
        resetProgressButton.waitUntil(\.isHittable, equals: true).tap()
        return self
    }

    func chooseLanguage() -> LanguagePickerScreen {
        languageButton.waitUntil(\.isHittable, equals: true).tap()
        return LanguagePickerScreen(app: app).waitUntilShown()
    }

    func chooseCollections() -> AddToCollectionScreen {
        collectionsButton.waitUntil(\.isHittable, equals: true).tap()
        return AddToCollectionScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func done() -> LibraryScreen {
        leave(tapping: doneButton)
    }

    @discardableResult
    func cancel() -> LibraryScreen {
        leave(tapping: cancelButton)
    }

    private func leave(tapping button: XCUIElement) -> LibraryScreen {
        button.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return LibraryScreen(app: app).waitUntilShown()
    }

    private func replaceText(in field: XCUIElement, with text: String) throws -> Self {
        let field = field.waitUntil(\.isHittable, equals: true)
        let current = try XCTUnwrap(field.stringValue)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text + "\n")
        return self
    }
}
