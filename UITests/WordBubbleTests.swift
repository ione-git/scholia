import XCTest

final class WordBubbleTests: UITestCase {
    private let bubbleWidth: CGFloat = 236
    private let edgeInset: CGFloat = 16
    private let firstPage = "1 of 54"

    func testBubbleShowsWordAndLoadingWhileTranslating() throws {
        let reader = openGermanBook(translation: .held)

        try reader.tapWord(onLine: 0, x: 3)

        reader.bubbleWord.waitUntil(\.label, equals: "Als")
        XCTAssertEqual(reader.bubbleLoading.waitUntilExists().label, "Translating Als")
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → en")
        XCTAssertFalse(reader.bubbleTranslation.exists)
        XCTAssertEqual(reader.bubble.frame.width, bubbleWidth)
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        let tint = try wordColor(onLine: 0, in: reader)
        XCTAssertLessThanOrEqual(tint.found.distance(to: tint.tinted), 6, "\(tint)")
        attachScreenshot("Reader-Loading")
    }

    func testBubbleFillsInTranslation() throws {
        let reader = openGermanBook(translation: .immediate)

        try reader.tapWord(onLine: 6, x: 3)

        reader.bubbleWord.waitUntil(\.label, equals: "braunen")
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")
        XCTAssertEqual(reader.bubbleIPA.label, "[ˈʊnɡəˌtsiːfɐ]")
        XCTAssertEqual(reader.bubbleGrammar.label, "das Ungeziefer · noun")
        XCTAssertFalse(reader.bubbleLoading.exists)
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        attachScreenshot("Reader-Bubble")
    }

    func testBubbleIsClampedToPageEdges() throws {
        let reader = openGermanBook(translation: .immediate)

        try reader.tapWord(onLine: 4, x: 3)
        reader.bubbleWord.waitUntil(\.label, equals: "panzerartig")
        XCTAssertEqual(reader.bubble.frame.minX, edgeInset)

        try reader.tapWord(onLine: 4, x: 283)
        reader.bubbleWord.waitUntil(\.label, equals: "wenn")
        XCTAssertEqual(reader.bubble.frame.maxX, reader.app.frame.width - edgeInset)
    }

    func testBubbleFlipsBelowWordNearTopOfPage() throws {
        let reader = openGermanBook(translation: .immediate)
        let heading = reader.germanHeading.waitUntilExists().coordinate(
            withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5))
        let fifthLine = try reader.wordPoint(onLine: 4, x: 3)

        heading.tap()
        reader.bubbleWord.waitUntil(\.label, equals: "Erster")
        XCTAssertGreaterThan(reader.bubble.frame.minY, heading.screenPoint.y)
        XCTAssertGreaterThan(reader.bubble.frame.minY, reader.root.frame.maxY)

        fifthLine.tap()
        reader.bubbleWord.waitUntil(\.label, equals: "panzerartig")
        XCTAssertLessThan(reader.bubble.frame.maxY, fifthLine.screenPoint.y)
        XCTAssertGreaterThanOrEqual(reader.bubble.frame.minY, reader.root.frame.maxY)
    }

    func testTapOutsideClosesBubbleWithoutChromeAndTapOnBubbleKeepsIt() throws {
        let reader = openGermanBook(translation: .immediate)
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        try reader.tapWord(onLine: 4, x: 3)
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")

        reader.bubble.tap()
        try reader.tapWord(onLine: 7, x: 170)

        reader.bubbleWord.waitUntil(\.label, equals: "auf")
        reader.translationRequests.waitUntil(\.label, equals: "panzerartig · 18 · de → en\nauf · 161 · de → en")
        XCTAssertFalse(reader.backButton.exists)

        reader.tapMargin()

        reader.bubble.waitUntilGone()
        XCTAssertFalse(reader.backButton.exists)
        XCTAssertEqual(reader.pageCounter.label, firstPage)
        reader.showChrome()
    }

    func testPageTurnClosesBubbleAndClearsTint() throws {
        let reader = openGermanBook(translation: .immediate)
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        try reader.tapWord(onLine: 0, x: 3)
        reader.bubbleWord.waitUntil(\.label, equals: "Als")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")

        reader.turnForward(expecting: "2 of 54")

        reader.bubble.waitUntilGone()
        reader.turnBackward(expecting: firstPage)
        reader.paintedWordTints.waitUntil(\.label, equals: "0")
        let tint = try wordColor(onLine: 0, in: reader)
        XCTAssertLessThanOrEqual(tint.found.distance(to: tint.page), 2, "\(tint)")
    }

    func testTappingAnotherWordWhileLoadingSwitchesBubble() throws {
        let reader = openGermanBook(translation: .held)
        try reader.tapWord(onLine: 0, x: 3)
        reader.bubbleWord.waitUntil(\.label, equals: "Als")
        reader.bubbleLoading.waitUntilExists()

        try reader.tapWord(onLine: 7, x: 170)

        reader.bubbleWord.waitUntil(\.label, equals: "auf")
        XCTAssertEqual(reader.bubbleLoading.waitUntilExists().label, "Translating auf")
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → en\nauf · 161 · de → en")
        XCTAssertFalse(reader.bubbleTranslation.exists)
    }

    func testBubbleAndTintFollowNightThemeInDarkAppearance() throws {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = .dark
        let reader = openGermanBook(translation: .immediate)

        try reader.tapWord(onLine: 6, x: 3)

        reader.bubbleWord.waitUntil(\.label, equals: "braunen")
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        let tint = try wordColor(onLine: 6, in: reader)
        XCTAssertLessThanOrEqual(tint.found.distance(to: tint.tinted), 6, "\(tint)")
        attachScreenshot("Reader-Dark")
    }

    func testBookInTargetLanguageNeedsNoTranslation() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let settings = HomeScreen(app: app).waitUntilShown().openSettings()
        settings.chooseTranslationLanguage("de")
        let reader = settings.goBack().openHeroBook()

        try reader.tapWord(onLine: 0, x: 3)

        reader.bubbleWord.waitUntil(\.label, equals: "Als")
        XCTAssertEqual(reader.bubbleFailure.waitUntilExists().label, "No translation needed")
        XCTAssertFalse(reader.bubbleLoading.exists)
        XCTAssertEqual(reader.translationRequests.label, "")
    }

    private func openGermanBook(translation: TranslationMock) -> ReaderScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: translation, now: nil,
                notificationPermission: nil))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.germanParagraph.waitUntilExists()
        return reader
    }

    private func wordColor(onLine index: Int, in reader: ReaderScreen) throws -> (found: RGB, page: RGB, tinted: RGB) {
        let tokens = try TokenValues.load()
        let dark = XCUIDevice.shared.appearance == .dark
        let page = try tokens.color("surface-paper", dark: dark)
        let tinted = try tokens.color("word-tap", dark: dark, over: page)
        let point = try reader.wordPoint(onLine: index, x: 3).screenPoint
        let pixels = try ScreenPixels(XCUIScreen.main.screenshot(), pointWidth: reader.app.frame.width)
        let area = CGRect(x: point.x, y: point.y - 3, width: 16, height: 6)
        let found = try XCTUnwrap(pixels.colors(in: area).min { $0.distance(to: page) < $1.distance(to: page) })
        return (found, page, tinted)
    }
}
