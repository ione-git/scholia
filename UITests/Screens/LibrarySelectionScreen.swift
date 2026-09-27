import XCTest

struct LibrarySelectionScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { title }

    var title: XCUIElement { app.staticTexts["librarySelection.title"] }
    var cancelButton: XCUIElement { app.buttons["librarySelection.cancel"] }
    var doneButton: XCUIElement { app.buttons["librarySelection.done"] }
    var collectionButton: XCUIElement { app.buttons["librarySelection.collection"] }
    var finishedButton: XCUIElement { app.buttons["librarySelection.finished"] }
    var removeButton: XCUIElement { app.buttons["librarySelection.remove"] }

    func book(_ title: String) -> XCUIElement { app.buttons["library.book.\(title)"] }

    @discardableResult
    func toggle(_ title: String) -> Self {
        let book = book(title).waitUntil(\.isHittable, equals: true)
        let wasSelected = book.isSelected
        book.tap()
        book.waitUntil(\.isSelected, equals: !wasSelected)
        return self
    }

    @discardableResult
    func cancel() -> LibraryScreen {
        leave(tapping: cancelButton)
    }

    @discardableResult
    func done() -> LibraryScreen {
        leave(tapping: doneButton)
    }

    @discardableResult
    func toggleFinished() -> LibraryScreen {
        leave(tapping: finishedButton)
    }

    func addToCollection() -> AddToCollectionScreen {
        collectionButton.waitUntil(\.isHittable, equals: true).tap()
        return AddToCollectionScreen(app: app).waitUntilShown()
    }

    func remove() -> RemoveBooksDialog {
        removeButton.waitUntil(\.isHittable, equals: true).tap()
        return RemoveBooksDialog(app: app).waitUntilShown()
    }

    private func leave(tapping button: XCUIElement) -> LibraryScreen {
        button.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return LibraryScreen(app: app).waitUntilShown()
    }
}
