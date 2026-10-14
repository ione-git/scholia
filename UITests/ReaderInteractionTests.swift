import XCTest

final class ReaderInteractionTests: UITestCase {
    func testSelectionDismissalRestoresChromeAndNativeMenu() throws {
        let reader = openReader()
        let selection = try reader.selectWord(onLine: 2, x: 20)
        reader.tapMargin()
        selection.root.waitUntilGone()
        assertChromeAndContents(reader)
    }

    func testHighlightMenuDismissalRestoresChromeAndNativeMenu() throws {
        let reader = openReader()
        try reader.selectWord(onLine: 2, x: 20).highlight()
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        let highlight = try reader.tapHighlight(onLine: 2, x: 20)
        reader.tapMargin()
        highlight.root.waitUntilGone()
        assertChromeAndContents(reader)
    }

    func testDragHighlightRestoresChromeAndNativeMenu() throws {
        let reader = openReader()
        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 2, x: 20, toLine: 3, x: 100)
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        assertChromeAndContents(reader)
    }

    func testChromeReturnsAfterPaintingOverSavedHighlightAndRecolouring() throws {
        let reader = openReader()
        try reader.selectWord(onLine: 2, x: 20).highlight()
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 2, x: 20, toLine: 3, x: 100)
        reader.paintedLive.waitUntil(\.label, equals: "0")
        try reader.tapHighlight(onLine: 2, x: 20).choose("green")
        try reader.selectWord(onLine: 6, x: 20).copy()
        assertChromeAndContents(reader)
    }

    func testBookmarkRemainsSelectedAfterLineSpacingChanges() {
        let reader = openReader(animated: true)
        reader.showChrome()
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        let settings = reader.openSettings()
        for spacing in ["tight", "loose", "normal"] {
            settings.choose(settings.lineSpacing(spacing))
            XCTAssertTrue(reader.bookmarkButton.isSelected)
        }
        settings.closeByTappingPage(reader)
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
    }

    func testScrollBookmarkAndHighlightJumpsKeepTheirPlaces() {
        let reader = openReader(highlighted: true)
        let settings = reader.openSettings()
        settings.choose(settings.pageTurn("scroll"))
        reader.appearance.waitUntil(\.label, satisfies: { $0.hasSuffix("scroll") })
        settings.closeByTappingPage(reader)
        reader.openMenu().open("contents").jump(to: "Dritter Teil")
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Dritter Teil")
        reader.bookmarkButton.waitUntil(\.isEnabled, equals: true)
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        reader.openMenu().open("contents").jump(to: "Erster Teil")
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Erster Teil")
        reader.openMenu().open("bookmarks").jump(toBookmarkOnPage: 37)
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Dritter Teil")
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        let highlights = reader.openMenu().open("highlights")
        highlights.jump(toHighlight: highlights.highlights[0])
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Erster Teil")
        reader.bookmarkButton.waitUntil(\.isSelected, equals: false)
        XCTAssertEqual(reader.storedHighlights.label, "7")
    }

    func testScrollChapterJumpSnapshotLight() {
        assertSnapshot(of: scrollChapter(appearance: .light), named: "Reader-Scroll-Destination")
    }

    func testScrollChapterJumpSnapshotDark() {
        assertSnapshot(of: scrollChapter(appearance: .dark), named: "Reader-Scroll-Destination")
    }

    func testScrollQuietSnapshotLight() throws {
        assertSnapshot(of: try scrolledReader(appearance: .light), named: "Reader-Scroll-Quiet")
    }

    func testScrollQuietSnapshotDark() throws {
        assertSnapshot(of: try scrolledReader(appearance: .dark), named: "Reader-Scroll-Quiet")
    }

    private func assertChromeAndContents(_ reader: ReaderScreen) {
        reader.showChrome()
        reader.title.waitUntil(\.label, equals: "Die Verwandlung")
        reader.bookmarkButton.waitUntil(\.isHittable, equals: true)
        reader.menuButton.waitUntil(\.isHittable, equals: true)
        let contents = reader.openMenu().open("contents")
        contents.chapter("Erster Teil").waitUntil(\.isSelected, equals: true)
        contents.done()
    }

    private func scrollChapter(appearance: XCUIDevice.Appearance) -> ReaderScreen {
        let reader = openReader(appearance: appearance)
        let settings = reader.openSettings()
        settings.choose(settings.pageTurn("scroll"))
        reader.appearance.waitUntil(\.label, satisfies: { $0.hasSuffix("scroll") })
        settings.closeByTappingPage(reader)
        let jumped = reader.openMenu().open("contents").jump(to: "Dritter Teil")
        jumped.subtitle.waitUntil(\.label, equals: "Franz Kafka · Dritter Teil")
        jumped.hideChrome()
        return jumped
    }

    private func scrolledReader(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        let reader = openReader(appearance: appearance, highlighted: true)
        let settings = reader.openSettings()
        settings.choose(settings.pageTurn("scroll"))
        reader.appearance.waitUntil(\.label, satisfies: { $0.hasSuffix("scroll") })
        reader.pageCounter.waitUntil(\.label, equals: "1 of 54")
        settings.closeByTappingPage(reader)
        let highlights = reader.openMenu().open("highlights")
        let jumped = highlights.jump(toHighlight: highlights.highlights[0])
        jumped.hideChrome()
        return jumped
    }

    private func openReader(
        appearance: XCUIDevice.Appearance = .light, animated: Bool = false, highlighted: Bool = false
    ) -> ReaderScreen {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.german]
        if highlighted { configuration.highlighted = [.german] }
        let app =
            animated
            ? launchWithAnimations(configuration, appearance: appearance)
            : launch(configuration, appearance: appearance)
        return HomeScreen(app: app).waitUntilShown().openHeroBook()
    }
}
