import XCTest

struct LanguagePickerScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { searchField }

    var searchField: XCUIElement { app.searchFields["languagePicker.searchField"] }
    var backButton: XCUIElement { app.buttons["languagePicker.back"] }

    private static let languagePrefix = "languagePicker.language."

    var languages: [String] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", Self.languagePrefix))
            .allElementsBoundByIndex.map { String($0.identifier.dropFirst(Self.languagePrefix.count)) }
    }

    func language(_ code: String) -> XCUIElement { app.buttons[Self.languagePrefix + code] }

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
