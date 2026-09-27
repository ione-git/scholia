import XCTest

struct BookMenuScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { infoButton }

    var addToCollectionButton: XCUIElement { app.buttons["bookMenu.addToCollection"] }
    var finishedButton: XCUIElement { app.buttons["bookMenu.finished"] }
    var infoButton: XCUIElement { app.buttons["bookMenu.info"] }
    var removeButton: XCUIElement { app.buttons["bookMenu.remove"] }

    func addToCollection() -> AddToCollectionScreen {
        choose(addToCollectionButton)
        return AddToCollectionScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func toggleFinished() -> LibraryScreen {
        choose(finishedButton)
        return LibraryScreen(app: app).waitUntilShown()
    }

    func openInfo() -> BookInfoScreen {
        choose(infoButton)
        return BookInfoScreen(app: app).waitUntilShown()
    }

    func remove() -> RemoveBooksDialog {
        choose(removeButton)
        return RemoveBooksDialog(app: app).waitUntilShown()
    }

    private func choose(_ item: XCUIElement) {
        item.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
    }
}
