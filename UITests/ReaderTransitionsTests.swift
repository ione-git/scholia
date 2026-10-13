import XCTest

final class ReaderTransitionsTests: UITestCase {
    private let arabicBook = LaunchConfiguration(
        resetsState: true, fixtures: [.arabic], opened: [], inProgress: [], highlighted: [], translation: .immediate,
        now: nil, notificationPermission: nil)

    func testAnimatedSlideCrossesChaptersAndKeepsFinalPageAfterReopen() {
        let reader = HomeScreen(app: launchWithAnimations(arabicBook, appearance: .light)).waitUntilShown()
            .openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "1 of 9")

        for page in 2...5 {
            reader.turnForwardRightToLeft(expecting: "\(page) of 9")
        }
        reader.turnBackwardRightToLeft(expecting: "4 of 9")
        reader.turnBackwardRightToLeft(expecting: "3 of 9")

        let reopened = reader.backToHome().openHeroBook()
        reopened.pageCounter.waitUntil(\.label, equals: "3 of 9")
        reopened.turnForwardRightToLeft(expecting: "4 of 9")
    }

    func testBookmarkJumpAcrossChaptersAllowsSlideInBothDirections() {
        let reader = HomeScreen(app: launchWithAnimations(arabicBook, appearance: .light)).waitUntilShown()
            .openHeroBook()
        reader.turnForwardRightToLeft(expecting: "2 of 9")
        reader.turnForwardRightToLeft(expecting: "3 of 9")
        reader.turnForwardRightToLeft(expecting: "4 of 9")
        reader.turnForwardRightToLeft(expecting: "5 of 9")
        reader.showChrome()
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        reader.turnBackwardRightToLeft(expecting: "4 of 9")
        reader.turnBackwardRightToLeft(expecting: "3 of 9")
        reader.turnBackwardRightToLeft(expecting: "2 of 9")

        reader.openMenu().open("bookmarks").jump(toBookmarkOnPage: 5)

        reader.pageCounter.waitUntil(\.label, equals: "5 of 9")
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        reader.turnForwardRightToLeft(expecting: "6 of 9")
        reader.turnBackwardRightToLeft(expecting: "5 of 9")
        reader.turnBackwardRightToLeft(expecting: "4 of 9")
    }
}
