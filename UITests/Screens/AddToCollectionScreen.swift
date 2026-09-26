import XCTest

struct AddToCollectionScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { doneButton }

    var cancelButton: XCUIElement { app.buttons["addToCollection.cancel"] }
    var doneButton: XCUIElement { app.buttons["addToCollection.done"] }
    var bookTitle: XCUIElement { app.staticTexts["addToCollection.bookTitle"] }
    var bookAuthor: XCUIElement { app.staticTexts["addToCollection.bookAuthor"] }
    var newCollectionButton: XCUIElement { app.buttons["addToCollection.newCollection"] }

    private static let collectionPrefix = "addToCollection.collection."

    func collection(_ name: String) -> XCUIElement { app.buttons[Self.collectionPrefix + name] }

    var collections: [String] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", Self.collectionPrefix))
            .allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }
            .map { String($0.identifier.dropFirst(Self.collectionPrefix.count)) }
    }

    @discardableResult
    func toggle(_ name: String) -> Self {
        let row = collection(name).waitUntil(\.isHittable, equals: true)
        let wasSelected = row.isSelected
        row.tap()
        row.waitUntil(\.isSelected, equals: !wasSelected)
        return self
    }

    func newCollection() -> NewCollectionAlert {
        newCollectionButton.waitUntil(\.isHittable, equals: true).tap()
        return NewCollectionAlert(app: app).waitUntilShown()
    }

    @discardableResult
    func done() -> AddBookScreen {
        doneButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return AddBookScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func cancel() -> AddBookScreen {
        cancelButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return AddBookScreen(app: app).waitUntilShown()
    }
}
