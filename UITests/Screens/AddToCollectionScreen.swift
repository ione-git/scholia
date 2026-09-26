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
        done(returningTo: AddBookScreen(app: app))
    }

    @discardableResult
    func cancel() -> AddBookScreen {
        cancel(returningTo: AddBookScreen(app: app))
    }

    @discardableResult
    func done<Next: Screen>(returningTo next: Next) -> Next {
        doneButton.waitUntil(\.isHittable, equals: true).tap()
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
