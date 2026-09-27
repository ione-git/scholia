import XCTest

struct WordCardScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.otherElements["wordCard"] }

    var word: XCUIElement { app.staticTexts["wordCard.word"] }
    var details: XCUIElement { app.staticTexts["wordCard.details"] }
    var translation: XCUIElement { app.staticTexts["wordCard.translation"] }
    var meaningInContext: XCUIElement { app.staticTexts["wordCard.meaningInContext"] }
    var meanings: XCUIElement { app.otherElements["wordCard.meanings"] }
    var loading: XCUIElement { app.descendants(matching: .any)["wordCard.loading"] }
    var failure: XCUIElement { app.staticTexts["wordCard.failure"] }
    var pronounceButton: XCUIElement { app.buttons["wordCard.pronounce"] }
    var closeButton: XCUIElement { app.buttons["wordCard.close"] }
    var pronunciations: XCUIElement { app.descendants(matching: .any)["debug.pronunciations"] }

    var meaningLabels: [String] {
        meanings.children(matching: .any).allElementsBoundByIndex.map(\.label)
    }

    func pronounce() {
        pronounceButton.waitUntil(\.isHittable, equals: true).tap()
    }

    @discardableResult
    func close() -> ReaderScreen {
        closeButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return ReaderScreen(app: app).waitUntilShown()
    }
}
