import XCTest

final class NativeNavigationTests: UITestCase {
    func testLanguagePickerBackSwipeKeepsUnsavedBookInfo() throws {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.minimalMetadata]
        let app = launchWithAnimations(configuration, appearance: .light)
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        let info = library.openBookMenu("Minimal").openInfo()
        try info.replaceTitle(with: "Unsaved title")
        let language = info.chooseLanguage()
        language.backButton.waitUntil(\.isHittable, equals: true)

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        language.root.waitUntilGone()
        info.titleField.waitUntil(\.stringValue, equals: "Unsaved title")
        info.cancel()
        library.book("Minimal").waitUntilExists()
        XCTAssertFalse(library.book("Unsaved title").exists)
    }
}
