import XCTest

final class ReaderCurlTests: UITestCase {
    private let germanBook = LaunchConfiguration(
        resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [], translation: .immediate,
        now: nil, notificationPermission: nil)
    private let arabicBook = LaunchConfiguration(
        resetsState: true, fixtures: [.arabic], opened: [], inProgress: [], highlighted: [], translation: .immediate,
        now: nil, notificationPermission: nil)
    private let bookPages = 54
    private let arabicBookPages = 9

    func testCurlIsSelectableAndTurnsPagesBothWays() {
        let reader = HomeScreen(app: launchWithAnimations(germanBook, appearance: .light)).waitUntilShown()
            .openHeroBook()
        let sheet = reader.openSettings()

        sheet.choose(sheet.pageTurn("curl"))
        XCTAssertFalse(sheet.pageTurn("slide").isSelected)
        sheet.closeByTappingPage(reader)
        reader.hideChrome()

        reader.curlForward(expecting: "2 of \(bookPages)")
        reader.curlForward(expecting: "3 of \(bookPages)")
        reader.curlBackward(expecting: "2 of \(bookPages)")
        reader.pageCurl.waitUntil(\.stringValue, equals: "3 completed, 0 cancelled")
    }

    func testReleasingEarlyKeepsThePage() {
        let reader = openInCurlMode(germanBook, appearance: .light)

        reader.curlBackwardDiagonally()
        XCTAssertEqual(reader.pageCurl.stringValue, "0 completed, 0 cancelled")
        XCTAssertEqual(reader.pageCounter.label, "1 of \(bookPages)")

        reader.curlAndRelease()

        reader.pageCurl.waitUntil(\.stringValue, equals: "0 completed, 1 cancelled")
        reader.pageCurl.waitUntil(\.label, equals: "ready")
        XCTAssertEqual(reader.pageCounter.label, "1 of \(bookPages)")
    }

    func testCurlFollowsRightToLeftAcrossChapters() {
        let reader = openInCurlMode(arabicBook, appearance: .light)

        for page in 2...5 {
            reader.curlForwardRightToLeft(expecting: "\(page) of \(arabicBookPages)")
        }
        reader.curlBackwardRightToLeft(expecting: "4 of \(arabicBookPages)")
        reader.curlBackwardRightToLeft(expecting: "3 of \(arabicBookPages)")
    }

    func testCurlChoicePersistsAcrossRelaunch() {
        let app = launchWithAnimations(germanBook, appearance: .light)
        var reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        sheet.choose(sheet.pageTurn("curl"))
        app.terminate()

        reader = HomeScreen(app: relaunch()).waitUntilShown().openHeroBook()
        let reopened = reader.openSettings()

        reopened.pageTurn("curl").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(reopened.pageTurn("slide").isSelected)
        reopened.closeByTappingPage(reader)
        reader.hideChrome()
        reader.curlForward(expecting: "2 of \(bookPages)")
    }

    func testWordTapAndDragHighlightStillWorkInCurlMode() throws {
        let reader = openInCurlMode(germanBook, appearance: .light)
        reader.pageCurl.waitUntil(\.label, equals: "ready")

        try reader.wordPoint(onLine: 5, x: 60).press(
            forDuration: 1, thenDragTo: try reader.wordPoint(onLine: 6, x: 200))

        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        XCTAssertEqual(reader.pageCounter.label, "1 of \(bookPages)")
        XCTAssertEqual(reader.pageCurl.stringValue, "0 completed, 0 cancelled")

        try reader.tapWord(onLine: 0, x: 3)
        reader.bubbleWord.waitUntil(\.label, equals: "Als")

        reader.curlForward(expecting: "2 of \(bookPages)")
        reader.bubble.waitUntilGone()
    }

    func testReaderCurlSnapshotLight() {
        assertSnapshot(of: turnedPage(appearance: .light), named: "Reader-Curl")
    }

    func testReaderCurlSnapshotDark() {
        assertSnapshot(of: turnedPage(appearance: .dark), named: "Reader-Curl")
    }

    private func turnedPage(appearance: XCUIDevice.Appearance) -> ReaderScreen {
        let reader = openInCurlMode(germanBook, appearance: appearance)
        reader.curlForward(expecting: "2 of \(bookPages)")
        reader.pageCurl.waitUntil(\.stringValue, equals: "1 completed, 0 cancelled")
        reader.pageCurl.waitUntil(\.label, equals: "ready")
        return reader
    }

    private func openInCurlMode(_ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance)
        -> ReaderScreen
    {
        let reader = HomeScreen(app: launchWithAnimations(configuration, appearance: appearance)).waitUntilShown()
            .openHeroBook()
        let sheet = reader.openSettings()
        sheet.choose(sheet.pageTurn("curl"))
        sheet.closeByTappingPage(reader)
        reader.hideChrome()
        return reader
    }

    private func relaunch() -> XCUIApplication {
        launchWithAnimations(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil, notificationPermission: nil),
            appearance: .light)
    }
}
