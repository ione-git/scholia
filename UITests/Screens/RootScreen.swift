import XCTest

struct RootScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["root.placeholder"] }

    var tokenGalleryButton: XCUIElement { app.buttons["root.tokenGallery"] }

    var componentGalleryButton: XCUIElement { app.buttons["root.componentGallery"] }

    var launchScreenButton: XCUIElement { app.buttons["root.launchScreen"] }

    func openTokenGallery() -> TokenGalleryScreen {
        tokenGalleryButton.waitUntilExists().tap()
        return TokenGalleryScreen(app: app).waitUntilShown()
    }

    func openComponentGallery() -> ComponentGalleryScreen {
        componentGalleryButton.waitUntilExists().tap()
        return ComponentGalleryScreen(app: app).waitUntilShown()
    }

    func openLaunchScreen() -> LaunchScreen {
        launchScreenButton.waitUntilExists().tap()
        return LaunchScreen(app: app).waitUntilShown()
    }
}
