import XCTest

struct LibraryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["library.title"] }

    var backButton: XCUIElement { app.buttons["library.back"] }
    var moreButton: XCUIElement { app.buttons["library.more"] }
    var searchField: XCUIElement { app.searchFields["library.searchField"] }
    var collectionRow: XCUIElement { app.scrollViews["library.collections"] }
    var allChip: XCUIElement { app.buttons["library.allChip"] }
    var newCollectionChip: XCUIElement { app.buttons["library.newCollectionChip"] }

    private static let collectionChipPrefix = "library.collectionChip."

    func collectionChip(_ name: String) -> XCUIElement { app.buttons[Self.collectionChipPrefix + name] }

    var collectionChips: [String]? {
        elements(identifiedBy: Self.collectionChipPrefix)?
            .sorted { $0.frame.minX < $1.frame.minX }
            .map { String($0.identifier.dropFirst(Self.collectionChipPrefix.count)) }
    }

    func book(_ title: String) -> XCUIElement { app.descendants(matching: .any)["library.book.\(title)"] }

    var shownTitles: [String]? {
        elements(identifiedBy: "library.book.")?
            .sorted { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }
            .map(\.label)
    }

    func search(_ text: String) {
        searchField.waitUntilExists().tap()
        let current = searchField.value as? String ?? ""
        searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text)
    }

    @discardableResult
    func show(_ chip: XCUIElement) -> Self {
        chip.waitUntil(\.isHittable, equals: true).tap()
        chip.waitUntil(\.isSelected, equals: true)
        return self
    }

    func newCollection() -> NewCollectionAlert {
        newCollectionChip.waitUntil(\.isHittable, equals: true).tap()
        return NewCollectionAlert(app: app).waitUntilShown()
    }

    func openBook(_ title: String) -> ReaderScreen {
        book(title).waitUntil(\.isHittable, equals: true).tap()
        return ReaderScreen(app: app).waitUntilShown()
    }

    func openMenu() -> LibraryMenuScreen {
        moreButton.waitUntil(\.isHittable, equals: true).tap()
        return LibraryMenuScreen(app: app).waitUntilShown()
    }

    func openBookMenu(_ title: String) -> BookMenuScreen {
        book(title).waitUntil(\.isHittable, equals: true).press(forDuration: 1)
        return BookMenuScreen(app: app).waitUntilShown()
    }

    func selectBooks() -> LibrarySelectionScreen {
        let menu = openMenu()
        menu.selectBooks.waitUntil(\.isHittable, equals: true).tap()
        menu.root.waitUntilGone()
        return LibrarySelectionScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func sort(by option: String) -> LibraryScreen {
        let sortMenu = openMenu().openSort()
        sortMenu.option(option).waitUntil(\.isHittable, equals: true).tap()
        sortMenu.root.waitUntilGone()
        return self
    }

    @discardableResult
    func swipeBack() -> HomeScreen {
        root.waitUntil(\.isHittable, equals: true)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func goBack() -> HomeScreen {
        backButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }
}

struct LibraryMenuScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.buttons["libraryMenu.sortBy"] }

    var selectBooks: XCUIElement { app.buttons["libraryMenu.selectBooks"] }
    var newCollection: XCUIElement { app.buttons["libraryMenu.newCollection"] }

    func openNewCollection() -> NewCollectionAlert {
        newCollection.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return NewCollectionAlert(app: app).waitUntilShown()
    }

    func openSort() -> LibrarySortMenuScreen {
        root.waitUntil(\.isHittable, equals: true).tap()
        return LibrarySortMenuScreen(app: app).waitUntilShown()
    }
}

struct LibrarySortMenuScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { option("recentlyOpened") }

    func option(_ key: String) -> XCUIElement { app.buttons["librarySortMenu.\(key)"] }

    func closeByTappingOutside() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap()
        root.waitUntilGone()
    }
}
