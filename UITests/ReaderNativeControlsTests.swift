import XCTest

final class ReaderNativeControlsTests: UITestCase {
    func testBackSwipeStaysInReaderAndBackReturnsToLibrary() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.minimalMetadata]
        let app = launchWithAnimations(configuration, appearance: .light)
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        let reader = library.openBook("Minimal")
        reader.pageCounter.waitUntilExists()

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        reader.pageCounter.waitUntil(\.label, equals: "1 of 1")
        XCTAssertFalse(library.root.exists)
        reader.backToLibrary().root.waitUntil(\.isHittable, equals: true)
        library.swipeBack()
        let home = HomeScreen(app: app).waitUntilShown()
        home.openSettings().swipeBack()
        home.settingsButton.waitUntil(\.isHittable, equals: true)
    }

    func testNativeTabsKeepBookmarksSeparateFromHighlights() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.german]
        let reader = HomeScreen(app: launch(configuration)).waitUntilShown().openHeroBook()
        reader.showChrome()
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        let index = reader.openMenu().open("bookmarks")
        index.bookmark(page: 1).waitUntilExists()
        XCTAssertTrue(index.highlights.isEmpty)

        index.tab("highlights").waitUntil(\.isHittable, equals: true).tap()
        index.tab("highlights").waitUntil(\.isSelected, equals: true)
        XCTAssertTrue(index.highlights.isEmpty)
        XCTAssertTrue(index.bookmarks.isEmpty)

        index.tab("bookmarks").waitUntil(\.isHittable, equals: true).tap()
        index.tab("bookmarks").waitUntil(\.isSelected, equals: true)
        index.bookmark(page: 1).waitUntilExists()
    }

}
