import XCTest

struct TokenGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["tokenGallery.scrollView"] }

    func open(_ section: String) -> TokenGallerySectionScreen {
        app.buttons["tokenGallery.\(section)"].waitUntilExists().tap()
        return TokenGallerySectionScreen(app: app, section: section).waitUntilShown().waitUntilSettled()
    }
}

struct TokenGallerySectionScreen: Screen {
    let app: XCUIApplication
    let section: String

    var root: XCUIElement { app.scrollViews["tokenGallery.section.\(section)"] }
}
