import XCTest

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

    func book(_ title: String) -> XCUIElement { app.descendants(matching: .any)["home.book.\(title)"] }

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

    private func openDebugMenu(_ item: String) {
        root.waitUntilExists().press(forDuration: 1)
        app.buttons[item].waitUntil(\.isHittable, equals: true).tap()
    }
}
