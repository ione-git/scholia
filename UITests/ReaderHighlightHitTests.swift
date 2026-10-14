import XCTest

final class ReaderHighlightHitTests: UITestCase {
    func testEmptySpaceBesideIndexHighlightRestoresChromeAndTextOpensPalette() throws {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.indexHighlights]
        configuration.highlighted = [.indexHighlights]
        let reader = HomeScreen(app: launch(configuration)).waitUntilShown().openHeroBook()
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        let entry = reader.paragraph(startingWith: "family of").waitUntilExists()
        let emptySpace = try reader.point(in: entry, onLine: 0, x: 250)
        emptySpace.tap()
        XCTAssertFalse(HighlightMenuScreen(app: reader.app).root.exists)
        reader.backButton.waitUntil(\.isHittable, equals: true)
        reader.menuButton.waitUntil(\.isHittable, equals: true)
        reader.openMenu().open("contents").done()
        try reader.point(in: entry, onLine: 0, x: 30).tap()
        let palette = HighlightMenuScreen(app: reader.app).waitUntilShown()
        emptySpace.tap()
        palette.root.waitUntilGone()
        reader.menuButton.waitUntil(\.isHittable, equals: true)
        try reader.point(in: entry, onLine: 0, x: 30).tap()
        palette.waitUntilShown().choose("green")
        try reader.point(in: entry, onLine: 0, x: 30).tap()
        HighlightMenuScreen(app: reader.app).waitUntilShown().delete()
        reader.paintedHighlights.waitUntil(\.label, equals: "0")
        XCTAssertEqual(reader.storedHighlights.label, "0")
    }
}
