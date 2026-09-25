import XCTest

struct LibraryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["library.title"] }

    var backButton: XCUIElement { app.buttons["library.back"] }
    var moreButton: XCUIElement { app.buttons["library.more"] }
    var searchField: XCUIElement { app.searchFields["library.searchField"] }

    func book(_ title: String) -> XCUIElement { app.descendants(matching: .any)["library.book.\(title)"] }

    var shownTitles: [String] {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "library.book."))
            .allElementsBoundByIndex
            .sorted { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }
            .map(\.label)
    }

    func search(_ text: String) {
        searchField.waitUntilExists().tap()
        let current = searchField.value as? String ?? ""
        searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text)
    }

    func openMenu() -> LibraryMenuScreen {
        moreButton.waitUntil(\.isHittable, equals: true).tap()
        return LibraryMenuScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func sort(by option: String) -> LibraryScreen {
        let sortMenu = openMenu().openSort()
        sortMenu.option(option).waitUntil(\.isHittable, equals: true).tap()
        sortMenu.root.waitUntilGone()
        return self
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

    func openSort() -> LibrarySortMenuScreen {
        root.waitUntil(\.isHittable, equals: true).tap()
        return LibrarySortMenuScreen(app: app).waitUntilShown()
    }
}

struct LibrarySortMenuScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.buttons["librarySortMenu.back"] }

    func option(_ key: String) -> XCUIElement { app.buttons["librarySortMenu.\(key)"] }

    func goBack() -> LibraryMenuScreen {
        root.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return LibraryMenuScreen(app: app).waitUntilShown()
    }
}
