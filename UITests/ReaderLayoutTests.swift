import XCTest

final class ReaderLayoutTests: UITestCase {
    func testNestedChapterJumpKeepsItsDestinationAndCurrentMarker() {
        let index = contents(appearance: .light)
        index.section("Part One").waitUntil(\.isHittable, equals: true)
        XCTAssertFalse(index.chapter("Part One").exists)
        index.scrollContents()
        index.chapter("Chapter 14").waitUntil(\.isHittable, equals: true)

        let reader = index.jump(to: "Chapter 12")

        reader.subtitle.waitUntil(\.label, equals: "Scholia · Chapter 12")
        let reopened = reader.openMenu().open("contents")
        reopened.chapter("Chapter 12").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(reopened.chapter("Part Two").isSelected)
    }

    func testNestedContentsSnapshotLight() {
        assertSnapshot(of: contents(appearance: .light), named: "Reader-Nested-Contents")
    }

    func testNestedContentsSnapshotDark() {
        assertSnapshot(of: contents(appearance: .dark), named: "Reader-Nested-Contents")
    }

    func testScrolledContentsSnapshotLight() {
        assertSnapshot(of: scrolledContents(appearance: .light), named: "Reader-Scrolled-Contents")
    }

    func testScrolledContentsSnapshotDark() {
        assertSnapshot(of: scrolledContents(appearance: .dark), named: "Reader-Scrolled-Contents")
    }

    func testQuietPageCounterSnapshotLight() {
        assertSnapshot(of: reader(appearance: .light), named: "Reader-Counter-Quiet")
    }

    func testQuietPageCounterSnapshotDark() {
        assertSnapshot(of: reader(appearance: .dark), named: "Reader-Counter-Quiet")
    }

    func testShownPageCounterSnapshotLight() {
        assertSnapshot(of: shownReader(appearance: .light), named: "Reader-Counter-Shown")
    }

    func testShownPageCounterSnapshotDark() {
        assertSnapshot(of: shownReader(appearance: .dark), named: "Reader-Counter-Shown")
    }

    private func contents(appearance: XCUIDevice.Appearance) -> ReaderIndexScreen {
        shownReader(appearance: appearance).openMenu().open("contents").waitUntilStartPagesShown()
    }

    private func scrolledContents(appearance: XCUIDevice.Appearance) -> ReaderIndexScreen {
        let index = contents(appearance: appearance)
        index.scrollContents()
        index.chapter("Chapter 14").waitUntil(\.isHittable, equals: true)
        return index
    }

    private func shownReader(appearance: XCUIDevice.Appearance) -> ReaderScreen {
        let reader = reader(appearance: appearance)
        reader.showChrome()
        return reader
    }

    private func reader(appearance: XCUIDevice.Appearance) -> ReaderScreen {
        let configuration = LaunchConfiguration(
            resetsState: true, fixtures: [.nestedContents], opened: [], inProgress: [], highlighted: [],
            translation: .immediate, now: nil, notificationPermission: nil)
        return HomeScreen(app: launch(configuration, appearance: appearance)).waitUntilShown().openHeroBook()
    }
}
