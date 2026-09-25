import XCTest

struct RootScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["root.placeholder"] }

    var tokenGalleryButton: XCUIElement { app.buttons["root.tokenGallery"] }

    func openTokenGallery() -> TokenGalleryScreen {
        tokenGalleryButton.waitUntilExists().tap()
        return TokenGalleryScreen(app: app).waitUntilShown()
    }
}
