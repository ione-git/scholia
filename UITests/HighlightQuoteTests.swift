import XCTest

final class HighlightQuoteTests: UITestCase {
    private let indexRange = "0:19-127"

    func testQuotePresentationPreservesSavedTextAndJumpAfterReopen() {
        let app = launch(indexBook)
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook().waitUntilOpened()
        reader.storedHighlights.waitUntil(\.label, equals: "1")
        let savedText = reader.storedHighlights.stringValue
        let page = reader.pageCounter.label

        reader.showChrome()
        let index = reader.openMenu().open("highlights")
        let jumped = index.jump(toHighlight: index.highlight(indexRange))
        jumped.pageCounter.waitUntil(\.label, equals: page)
        jumped.backToHome()
        app.terminate()

        var configuration = indexBook
        configuration.resetsState = false
        let reopenedApp = launch(configuration)
        let reopened = HomeScreen(app: reopenedApp).waitUntilShown().openHeroBook().waitUntilOpened()
        reopened.storedHighlights.waitUntil(\.stringValue, equals: savedText)
        reopened.showChrome()
        let reopenedIndex = reopened.openMenu().open("highlights")
        reopenedIndex.highlight(indexRange).waitUntilExists()
        XCTAssertEqual(reopenedIndex.highlights.count, 1)
    }

    func testIndexQuoteSnapshotLight() {
        assertSnapshot(of: openIndexHighlights(launch(indexBook, appearance: .light)), named: "Reader-Index-Quote")
    }

    func testIndexQuoteSnapshotDark() {
        assertSnapshot(of: openIndexHighlights(launch(indexBook, appearance: .dark)), named: "Reader-Index-Quote")
    }

    private var indexBook: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [.indexHighlights], opened: [], inProgress: [],
            highlighted: [.indexHighlights], translation: .immediate, now: nil, notificationPermission: nil)
    }

    private func openIndexHighlights(_ app: XCUIApplication) -> ReaderIndexScreen {
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook().waitUntilOpened()
        reader.showChrome()
        let index = reader.openMenu().open("highlights")
        index.highlight(indexRange).waitUntilExists()
        return index
    }
}
