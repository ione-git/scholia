import XCTest

final class ReaderNativeControlsTests: UITestCase {
    func testBackSwipeFromReaderReturnsToLibrary() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.minimalMetadata]
        let app = launchWithAnimations(configuration, appearance: .light)
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        let reader = library.openBook("Minimal")
        reader.pageCounter.waitUntilExists()

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        library.root.waitUntil(\.isHittable, equals: true)
        reader.pageCounter.waitUntilGone()
        library.goBack().settingsButton.waitUntil(\.isHittable, equals: true)
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
