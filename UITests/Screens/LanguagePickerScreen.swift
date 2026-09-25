import XCTest

struct LanguagePickerScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { searchField }

    var searchField: XCUIElement { app.searchFields["languagePicker.searchField"] }
    var backButton: XCUIElement { app.buttons["languagePicker.back"] }

    func language(_ code: String) -> XCUIElement { app.buttons["languagePicker.language.\(code)"] }

    @discardableResult
    func search(_ query: String) -> Self {
        searchField.waitUntil(\.isHittable, equals: true).tap()
        searchField.typeText(query)
        return self
    }

    @discardableResult
    func choose(_ code: String) -> AddBookScreen {
        language(code).waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return AddBookScreen(app: app).waitUntilShown()
    }
}
