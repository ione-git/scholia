import XCTest

private let bookOpenTimeout: TimeInterval = 30

struct HomeScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["home.wordmark"] }

    var goalRing: XCUIElement { app.descendants(matching: .any)["home.goalRing"] }
    var addBookButton: XCUIElement { app.buttons["home.addBook"] }
    var settingsButton: XCUIElement { app.buttons["home.settings"] }

    var heroCover: XCUIElement { app.descendants(matching: .any)["home.heroCover"] }
    var heroTitle: XCUIElement { app.staticTexts["home.heroTitle"] }
    var heroAuthor: XCUIElement { app.staticTexts["home.heroAuthor"] }
    var heroProgress: XCUIElement { app.descendants(matching: .any)["home.heroProgress"] }

    var libraryButton: XCUIElement { app.buttons["home.library"] }

    var emptyCover: XCUIElement { app.buttons["home.emptyCover"] }
    var emptyTitle: XCUIElement { app.staticTexts["home.emptyTitle"] }
    var emptyMessage: XCUIElement { app.staticTexts["home.emptyMessage"] }
    var emptyAddBookButton: XCUIElement { app.buttons["home.emptyAddBook"] }

    func book(_ title: String) -> XCUIElement { app.descendants(matching: .any)["home.book.\(title)"] }

    func background() throws -> RGBColor {
        try app.screenshot().color(at: CGPoint(x: 0.02, y: 0.9))
    }

    func heroCoverColor() throws -> RGBColor {
        try heroCover.screenshot().color(at: CGPoint(x: 0.5, y: 0.3))
    }

    func pickFile() -> FilePickerScreen {
        pickFile(tapping: addBookButton)
    }

    func pickFile(tapping button: XCUIElement) -> FilePickerScreen {
        button.waitUntil(\.isHittable, equals: true).tap()
        return FilePickerScreen(app: app).waitUntilShown()
    }

    func openFromOtherApp(_ fixture: Fixture) throws -> AddBookScreen {
        app.open(try fixture.file)
        return AddBookScreen(app: app).waitUntilShown()
    }

    func openUnreadableFromOtherApp(_ fixture: Fixture) throws -> ImportFailureAlert {
        app.open(try fixture.file)
        return ImportFailureAlert(app: app).waitUntilShown()
    }

    func openLibrary() -> LibraryScreen {
        libraryButton.waitUntilExists().tap()
        return LibraryScreen(app: app).waitUntilShown()
    }

    func openSettings() -> SettingsScreen {
        settingsButton.waitUntilExists().tap()
        return SettingsScreen(app: app).waitUntilShown()
    }

    func openTokenGallery() -> TokenGalleryScreen {
        openDebugMenu("home.tokenGallery")
        return TokenGalleryScreen(app: app).waitUntilShown()
    }

    func openComponentGallery() -> ComponentGalleryScreen {
        openDebugMenu("home.componentGallery")
        return ComponentGalleryScreen(app: app).waitUntilShown()
    }

    func openLaunchScreen() -> LaunchScreen {
        openDebugMenu("home.launchScreen")
        return LaunchScreen(app: app).waitUntilShown()
    }

    func openReaderPrototype() -> ReaderScreen {
        openDebugMenu("home.readerPrototype")
        let reader = ReaderScreen(app: app).waitUntilShown()
        XCTAssertTrue(
            reader.pageCounter.waitForExistence(timeout: bookOpenTimeout),
            "\(reader.pageCounter.description) did not appear")
        return reader
    }

    func openEPUB() -> FilePickerScreen {
        openDebugMenu("home.openEPUB")
        return FilePickerScreen(app: app).waitUntilShown()
    }

    private func openDebugMenu(_ item: String) {
        root.waitUntilExists().press(forDuration: 1)
        app.buttons[item].waitUntil(\.isHittable, equals: true).tap()
    }
}
