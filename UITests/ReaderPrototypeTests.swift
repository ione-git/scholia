import XCTest

final class ReaderPrototypeTests: UITestCase {
    private let firstSentence =
        "Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte, fand er sich in seinem Bett zu einem "
        + "ungeheueren Ungeziefer verwandelt."
    private let secondSentence =
        "Er lag auf seinem panzerartig harten Rücken und sah, wenn er den Kopf ein wenig hob, seinen gewölbten, "
        + "braunen, von bogenförmigen Versteifungen geteilten Bauch, auf dessen Höhe sich die Bettdecke, zum "
        + "gänzlichen Niedergleiten bereit, kaum noch erhalten konnte."

    func testOpensGermanFixtureOnFirstPage() {
        let reader = openReader()

        XCTAssertEqual(reader.runningHead.label, "Die Verwandlung")
        XCTAssertEqual(reader.pageCounter.label, "1 of 54")
        XCTAssertEqual(reader.pageCounter.value as? String, "0")
        attachScreenshot("Reader")
    }

    func testSwipeTurnsPages() {
        let reader = openReader()

        reader.turnForward(expecting: "2 of 54")
        reader.turnForward(expecting: "3 of 54")
        reader.turnBackward(expecting: "2 of 54")
    }

    func testSwipeCrossesChapterBoundaryBothWays() {
        let reader = openReader()
        for page in 2...18 {
            reader.turnForward(expecting: "\(page) of 54")
        }

        reader.turnForward(expecting: "19 of 54")
        XCTAssertEqual(reader.pageCounter.value as? String, "1")
        reader.turnBackward(expecting: "18 of 54")
        XCTAssertEqual(reader.pageCounter.value as? String, "0")
    }

    func testTapOnWordReturnsWordSentenceAndRect() throws {
        let reader = openReader()
        let line = try readingLineHeight()
        let paragraph = reader.paragraph(startingWith: "Als Gregor Samsa").waitUntilExists()
        let firstWord = paragraph.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 3, dy: line / 2))
        let compoundAfterHyphen = paragraph.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 3, dy: line * 4 + line / 2))

        firstWord.tap()
        reader.word.waitUntil(\.label, equals: "Als")
        XCTAssertEqual(reader.sentence.label, firstSentence)
        XCTAssertTrue(reader.wordTint.frame.contains(firstWord.screenPoint), "\(reader.wordTint.frame)")

        compoundAfterHyphen.tap()
        reader.word.waitUntil(\.label, equals: "panzerartig")
        XCTAssertEqual(reader.sentence.label, secondSentence)
        XCTAssertTrue(reader.wordTint.frame.contains(compoundAfterHyphen.screenPoint), "\(reader.wordTint.frame)")
        XCTAssertLessThanOrEqual(reader.wordTint.frame.height, line)
    }

    func testTapOnWordStopsAtLineBreaksAndBlocks() {
        let reader = openReader()
        for page in 2...18 {
            reader.turnForward(expecting: "\(page) of 54")
        }
        reader.turnForward(expecting: "19 of 54")
        let verse = reader.paragraph(startingWith: "Über allen Gipfeln").waitUntilExists()
        let stanza = reader.paragraph(startingWith: "Die Vögelein").waitUntilExists()

        verse.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -8, dy: 0)).tap()
        reader.word.waitUntil(\.label, equals: "Gipfeln")
        XCTAssertEqual(
            reader.sentence.label, "Über allen Gipfeln Ist Ruh, In allen Wipfeln Spürest du Kaum einen Hauch;")

        stanza.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -10, dy: 0)).tap()
        reader.word.waitUntil(\.label, equals: "Walde")
        XCTAssertEqual(reader.sentence.label, "Die Vögelein schweigen im Walde.")
    }

    func testTapOutsideWordsClearsWordAndTogglesControls() throws {
        let reader = openReader()
        let line = try readingLineHeight()
        let paragraph = reader.paragraph(startingWith: "Als Gregor Samsa").waitUntilExists()
        paragraph.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 3, dy: line / 2)).tap()
        reader.word.waitUntilExists()

        reader.tapMargin()

        reader.word.waitUntilGone()
        XCTAssertFalse(reader.theme("paper").exists)
        reader.tapMargin()
        reader.theme("paper").waitUntil(\.isHittable, equals: true)
        reader.tapMargin()
        reader.theme("paper").waitUntilGone()
    }

    func testPageTurnClearsTappedWord() throws {
        let reader = openReader()
        let line = try readingLineHeight()
        let paragraph = reader.paragraph(startingWith: "Als Gregor Samsa").waitUntilExists()
        paragraph.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 3, dy: line / 2)).tap()
        reader.word.waitUntil(\.label, equals: "Als")

        reader.turnForward(expecting: "2 of 54")

        reader.word.waitUntilGone()
        XCTAssertFalse(reader.wordTint.exists)
    }

    func testThemesRecolourPageAndText() throws {
        let reader = openReader()
        let tokens = try TokenValues.load()
        let line = try readingLineHeight()
        let paragraph = reader.paragraph(startingWith: "Als Gregor Samsa").waitUntilExists()
        let themes = [
            (name: "paper", page: ("surface-paper", false), text: ("ink", false), screen: "Reader"),
            (name: "sepia", page: ("surface-sepia", false), text: ("sepia-text", false), screen: ""),
            (name: "night", page: ("surface-paper", true), text: ("night-text", true), screen: "Reader-Dark"),
            (name: "black", page: ("surface-black", true), text: ("night-text", true), screen: "Reader-Black"),
        ]

        for theme in themes {
            reader.chooseTheme(theme.name)

            let page = try tokens.color(theme.page.0, dark: theme.page.1)
            let text = try tokens.color(theme.text.0, dark: theme.text.1)
            let pixels = try ScreenPixels(XCUIScreen.main.screenshot(), pointWidth: reader.app.frame.width)
            let margin = pixels.color(at: CGPoint(x: paragraph.frame.minX / 2, y: paragraph.frame.midY))
            let firstLine = CGRect(
                x: paragraph.frame.minX, y: paragraph.frame.minY, width: paragraph.frame.width, height: line)
            let ink = try XCTUnwrap(pixels.colors(in: firstLine).max { $0.distance(to: page) < $1.distance(to: page) })
            XCTAssertLessThanOrEqual(margin.distance(to: page), 2, "\(theme.name) page \(margin) != \(page)")
            XCTAssertLessThanOrEqual(ink.distance(to: text), 6, "\(theme.name) text \(ink) != \(text)")
            if !theme.screen.isEmpty {
                attachScreenshot(theme.screen)
            }
        }
    }

    func testOpenEPUBPresentsFilesPicker() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))

        let picker = HomeScreen(app: app).waitUntilShown().openEPUB()

        picker.root.waitUntil(\.isHittable, equals: true)
        attachScreenshot("FilePicker")
    }

    private func openReader() -> ReaderScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        return HomeScreen(app: app).waitUntilShown().openReaderPrototype()
    }

    private func readingLineHeight() throws -> CGFloat {
        try TokenValues.load().lineHeight("reading-body")
    }
}
