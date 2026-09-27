import XCTest

final class ReaderSettingsTests: UITestCase {
    private let germanBook = LaunchConfiguration(
        resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [], translation: .immediate,
        now: nil, notificationPermission: nil)
    private let bookPages = 54
    private let defaultStep = 3
    private let themes = ["paper", "sepia", "night", "black"]
    private let fonts = [
        (name: "charter", family: "Charter"), (name: "georgia", family: "Georgia"),
        (name: "system", family: "-apple-system"), (name: "literata", family: "Literata"),
    ]

    func testEachThemeRecoloursPageMovesRingAndPersists() throws {
        var app = launchWithGermanBook()
        var reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.appearance.waitUntil(\.label, equals: try style(theme: "paper"))
        let sheet = reader.openSettings()
        sheet.theme("paper").waitUntil(\.isSelected, equals: true)

        for theme in themes {
            sheet.choose(sheet.theme(theme))

            reader.appearance.waitUntil(\.label, equals: try style(theme: theme))
            for other in themes where other != theme {
                XCTAssertFalse(sheet.theme(other).isSelected, other)
            }
        }
        app.terminate()

        app = relaunch()
        reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.appearance.waitUntil(\.label, equals: try style(theme: "black"))
        reader.openSettings().theme("black").waitUntil(\.isSelected, equals: true)
    }

    func testEachFontChangesPageTypeface() throws {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        sheet.font("literata").waitUntil(\.isSelected, equals: true)

        for font in fonts {
            sheet.choose(sheet.font(font.name))

            reader.appearance.waitUntil(\.label, equals: try style(family: font.family))
            for other in fonts where other.name != font.name {
                XCTAssertFalse(sheet.font(other.name).isSelected, other.name)
            }
        }
    }

    func testSizeButtonsAndSliderChangeTextSizeAndPageCount() throws {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        XCTAssertEqual(sheet.size.stringValue, sizeValue(defaultStep))
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")

        sheet.step(sheet.larger, expecting: sizeValue(4))
        reader.appearance.waitUntil(\.label, equals: try style(step: 4))
        reader.pageCounter.waitUntil(\.label, satisfies: { total(in: $0) > self.bookPages })

        sheet.step(sheet.smaller, expecting: sizeValue(3))
        sheet.step(sheet.smaller, expecting: sizeValue(2))
        reader.appearance.waitUntil(\.label, equals: try style(step: 2))
        reader.pageCounter.waitUntil(\.label, satisfies: { total(in: $0) < self.bookPages })
        sheet.step(sheet.smaller, expecting: sizeValue(1))
        sheet.smaller.waitUntil(\.isEnabled, equals: false)

        sheet.slideSize(to: 1)
        sheet.size.waitUntil(\.stringValue, equals: sizeValue(7))
        reader.appearance.waitUntil(\.label, equals: try style(step: 7))
        sheet.larger.waitUntil(\.isEnabled, equals: false)
        XCTAssertTrue(sheet.smaller.isEnabled)

        sheet.slideSize(to: 1.0 / 3)
        sheet.size.waitUntil(\.stringValue, equals: sizeValue(defaultStep))
        reader.appearance.waitUntil(\.label, equals: try style(step: defaultStep))
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
    }

    func testEachLineSpacingChangesLineHeightAndPageCount() throws {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        sheet.lineSpacing("normal").waitUntil(\.isSelected, equals: true)

        sheet.choose(sheet.lineSpacing("tight"))
        reader.appearance.waitUntil(\.label, equals: try style(spacing: \.tight))
        reader.pageCounter.waitUntil(\.label, satisfies: { total(in: $0) < self.bookPages })
        XCTAssertFalse(sheet.lineSpacing("normal").isSelected)

        sheet.choose(sheet.lineSpacing("loose"))
        reader.appearance.waitUntil(\.label, equals: try style(spacing: \.loose))
        reader.pageCounter.waitUntil(\.label, satisfies: { total(in: $0) > self.bookPages })
        XCTAssertFalse(sheet.lineSpacing("tight").isSelected)

        sheet.choose(sheet.lineSpacing("normal"))
        reader.appearance.waitUntil(\.label, equals: try style(spacing: \.normal))
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
    }

    func testFadeTurnsPagesWithSwipes() throws {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()

        sheet.choose(sheet.pageTurn("fade"))
        XCTAssertFalse(sheet.pageTurn("slide").isSelected)
        reader.appearance.waitUntil(\.label, equals: try style(pageTurn: "fade"))
        sheet.closeByTappingPage(reader)

        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.turnBackward(expecting: "2 of \(bookPages)")
    }

    func testScrollAdvancesVerticallyCountsPagesAndReopensAtSamePlace() throws {
        let app = launchWithGermanBook()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()

        sheet.choose(sheet.pageTurn("scroll"))
        reader.appearance.waitUntil(\.label, equals: try style(pageTurn: "scroll"))
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
        reader.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0) != nil })
        let top = try XCTUnwrap(span(in: reader.appearance.stringValue))
        sheet.closeByTappingPage(reader)
        reader.hideChrome()
        scrollDown(app)

        reader.appearance.waitUntil(\.stringValue, satisfies: { (span(in: $0)?.start ?? 0) > top.start })
        let scrolled = try XCTUnwrap(span(in: reader.appearance.stringValue))
        reader.pageCounter.waitUntil(\.label, satisfies: { number(in: $0) > 1 })
        let page = number(in: reader.pageCounter.label)
        let home = reader.backToHome()
        home.heroProgress.waitUntil(\.stringValue, equals: percent(page, of: bookPages))
        let reopened = home.openHeroBook()
        reopened.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0)?.contains(scrolled.start) == true })
        reopened.pageCounter.waitUntil(\.label, satisfies: { number(in: $0) > 1 })
    }

    func testSlideAfterScrollShowsPagesAtScrolledPlace() throws {
        let app = launchWithGermanBook()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        var sheet = reader.openSettings()
        sheet.choose(sheet.pageTurn("scroll"))
        reader.appearance.waitUntil(\.label, equals: try style(pageTurn: "scroll"))
        sheet.closeByTappingPage(reader)
        reader.hideChrome()
        scrollDown(app)
        reader.appearance.waitUntil(\.stringValue, satisfies: { (span(in: $0)?.start ?? 0) > 0 })
        let scrolled = try XCTUnwrap(span(in: reader.appearance.stringValue))
        sheet = reader.openSettings()

        sheet.choose(sheet.pageTurn("slide"))

        XCTAssertFalse(sheet.pageTurn("scroll").isSelected)
        reader.appearance.waitUntil(\.label, equals: try style(pageTurn: "slide"))
        reader.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0)?.contains(scrolled.start) == true })
        reader.pageCounter.waitUntil(\.label, satisfies: { number(in: $0) > 1 })
        let page = number(in: reader.pageCounter.label)
        sheet.closeByTappingPage(reader)
        reader.turnForward(expecting: "\(page + 1) of \(bookPages)")
    }

    func testSizeChangeKeepsReadingPlace() throws {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        for page in 2...5 {
            reader.turnForward(expecting: "\(page) of \(bookPages)")
        }
        reader.appearance.waitUntil(\.stringValue, satisfies: { (span(in: $0)?.start ?? 0) > 0 })
        let before = try XCTUnwrap(span(in: reader.appearance.stringValue))
        let sheet = reader.openSettings()

        sheet.step(sheet.larger, expecting: sizeValue(4))

        reader.appearance.waitUntil(\.label, equals: try style(step: 4))
        reader.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0)?.contains(before.start) == true })
    }

    func testFontChosenWhileSizeChangeLoadsKeepsTrackingPages() throws {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        for page in 2...4 {
            reader.turnForward(expecting: "\(page) of \(bookPages)")
        }
        reader.appearance.waitUntil(\.stringValue, satisfies: { (span(in: $0)?.start ?? 0) > 0 })
        let before = try XCTUnwrap(span(in: reader.appearance.stringValue))
        let sheet = reader.openSettings()

        sheet.larger.tap()
        sheet.font("charter").tap()

        reader.appearance.waitUntil(
            \.label, equals: try style(theme: "paper", family: "Charter", step: 4, spacing: \.normal, pageTurn: "slide")
        )
        reader.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0)?.contains(before.start) == true })
        reader.pageCounter.waitUntil(\.label, satisfies: { number(in: $0) > 1 })
        let counter = reader.pageCounter.label
        sheet.closeByTappingPage(reader)
        reader.turnForward(expecting: "\(number(in: counter) + 1) of \(total(in: counter))")
    }

    func testRotationLockHoldsInReaderAndContentsAndReleasesOnLeaving() throws {
        let app = try launchWithRotationLock()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        let window = app.windows.firstMatch
        let sheet = reader.openSettings()
        sheet.setLockRotation(true)
        sheet.closeByTappingPage(reader)

        XCUIDevice.shared.orientation = .landscapeLeft
        let index = reader.openMenu().open("contents")
        XCTAssertEqual(window.verticalSizeClass, .regular)
        index.done()
        reader.backButton.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(window.verticalSizeClass, .regular)

        reader.backToHome()

        window.waitUntil(\.verticalSizeClass, equals: .compact)
    }

    func testTurningRotationLockOffRotatesToDeviceOrientation() throws {
        let app = try launchWithRotationLock()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        let window = app.windows.firstMatch
        var sheet = reader.openSettings()
        sheet.setLockRotation(true)
        sheet.closeByTappingPage(reader)

        XCUIDevice.shared.orientation = .landscapeLeft
        sheet = reader.openSettings()
        XCTAssertEqual(window.verticalSizeClass, .regular)
        sheet.setLockRotation(false)

        window.waitUntil(\.verticalSizeClass, equals: .compact)
    }

    func testRotationLockPersistsAcrossRelaunch() throws {
        var app = try launchWithRotationLock()
        HomeScreen(app: app).waitUntilShown().openHeroBook().openSettings().setLockRotation(true)
        app.terminate()

        app = relaunch()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        let window = app.windows.firstMatch
        XCUIDevice.shared.orientation = .landscapeLeft
        let sheet = reader.openSettings()
        XCTAssertEqual(sheet.lockRotation.stringValue, "1")
        XCTAssertEqual(window.verticalSizeClass, .regular)
        sheet.closeByTappingPage(reader)
        reader.backToHome()

        window.waitUntil(\.verticalSizeClass, equals: .compact)
    }

    func testDarkAppearanceShowsNightForPaperAndPickedPaperStaysUntilAppearanceChanges() throws {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = .dark
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))
        let sheet = reader.openSettings()
        sheet.theme("night").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(sheet.theme("paper").isSelected)

        XCUIDevice.shared.appearance = .light
        reader.appearance.waitUntil(\.label, equals: try style(theme: "paper"))
        sheet.theme("paper").waitUntil(\.isSelected, equals: true)

        XCUIDevice.shared.appearance = .dark
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))
        sheet.theme("night").waitUntil(\.isSelected, equals: true)

        sheet.choose(sheet.theme("paper"))
        reader.appearance.waitUntil(\.label, equals: try style(theme: "paper"))
        XCTAssertFalse(sheet.theme("night").isSelected)

        XCUIDevice.shared.appearance = .light
        XCUIDevice.shared.appearance = .dark
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))
        sheet.theme("night").waitUntil(\.isSelected, equals: true)
    }

    func testTappingShownNightInDarkKeepsChosenDayTheme() throws {
        let reader = HomeScreen(app: launch(germanBook, appearance: .dark)).waitUntilShown().openHeroBook()
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))
        let sheet = reader.openSettings()
        sheet.theme("night").waitUntil(\.isSelected, equals: true)

        sheet.theme("night").tap()
        XCUIDevice.shared.appearance = .light

        reader.appearance.waitUntil(\.label, equals: try style(theme: "paper"))
        sheet.theme("paper").waitUntil(\.isSelected, equals: true)
    }

    func testNightAfterPreviewingPaperInDarkKeepsPaperByDay() throws {
        try assertNightAfterPreviewKeepsDayTheme("paper")
    }

    func testNightAfterPreviewingSepiaInDarkKeepsSepiaByDay() throws {
        try assertNightAfterPreviewKeepsDayTheme("sepia")
    }

    func testTapOnPageClosesSheetAndKeepsChrome() {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()

        sheet.closeByTappingPage(reader)

        XCTAssertTrue(reader.backButton.isHittable)
        XCTAssertTrue(reader.menuButton.exists)
        XCTAssertEqual(reader.pageCounter.label, "1 of \(bookPages)")
    }

    func testEveryControlPersistsAcrossRelaunch() throws {
        var app = launchWithGermanBook()
        var reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        var sheet = reader.openSettings()
        sheet.choose(sheet.theme("sepia"))
        sheet.choose(sheet.font("charter"))
        sheet.slideSize(to: 4.0 / 6)
        sheet.size.waitUntil(\.stringValue, equals: sizeValue(5))
        sheet.choose(sheet.lineSpacing("loose"))
        sheet.choose(sheet.pageTurn("fade"))
        sheet.setLockRotation(true)
        let changed = try style(theme: "sepia", family: "Charter", step: 5, spacing: \.loose, pageTurn: "fade")
        reader.appearance.waitUntil(\.label, equals: changed)
        app.terminate()

        app = relaunch()
        reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.appearance.waitUntil(\.label, equals: changed)
        sheet = reader.openSettings()
        for option in [sheet.theme("sepia"), sheet.font("charter"), sheet.lineSpacing("loose"), sheet.pageTurn("fade")]
        {
            option.waitUntil(\.isSelected, equals: true)
        }
        XCTAssertEqual(sheet.size.stringValue, sizeValue(5))
        XCTAssertEqual(sheet.lockRotation.stringValue, "1")
        sheet.closeByTappingPage(reader)
        reader.turnForward(expecting: "2 of \(reader.pageCounter.label.components(separatedBy: " of ").last ?? "")")
    }

    func testReaderMenuSettingsSnapshotLight() {
        assertSnapshot(of: openSettingsWithLockedRotation(appearance: .light), named: "Reader-Menu-Settings")
    }

    func testReaderMenuSettingsSnapshotDark() {
        assertSnapshot(of: openSettingsWithLockedRotation(appearance: .dark), named: "Reader-Menu-Settings")
    }

    func testReaderBubbleSnapshotLight() throws {
        assertSnapshot(of: try openPageWithBubble(appearance: .light), named: "Reader-Bubble")
    }

    func testReaderBubbleSnapshotDark() throws {
        assertSnapshot(of: try openPageWithBubble(appearance: .dark), named: "Reader-Bubble")
    }

    func testReaderBlackSnapshotLight() throws {
        assertSnapshot(of: try openBlackPageWithBubble(appearance: .light), named: "Reader-Black")
    }

    func testReaderBlackSnapshotDark() throws {
        assertSnapshot(of: try openBlackPageWithBubble(appearance: .dark), named: "Reader-Black")
    }

    private func openSettingsWithLockedRotation(appearance: XCUIDevice.Appearance) -> ReaderSettingsScreen {
        let reader = HomeScreen(app: launch(germanBook, appearance: appearance)).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        sheet.setLockRotation(true)
        return sheet
    }

    private func openPageWithBubble(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        try showBubble(
            in: HomeScreen(app: launch(germanBook, appearance: appearance)).waitUntilShown().openHeroBook())
    }

    private func openBlackPageWithBubble(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        let reader = HomeScreen(app: launch(germanBook, appearance: appearance)).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        sheet.choose(sheet.theme("black"))
        sheet.closeByTappingPage(reader)
        reader.hideChrome()
        return try showBubble(in: reader)
    }

    private func showBubble(in reader: ReaderScreen) throws -> ReaderScreen {
        try reader.tapWord(onLine: 3, x: 3)
        reader.bubbleWord.waitUntil(\.label, equals: "Ungeziefer")
        reader.bubbleTranslation.waitUntilExists()
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        return reader
    }

    private func assertNightAfterPreviewKeepsDayTheme(_ dayTheme: String) throws {
        let reader = HomeScreen(app: launch(germanBook, appearance: .light)).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()
        sheet.choose(sheet.theme(dayTheme))
        XCUIDevice.shared.appearance = .dark
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))

        sheet.choose(sheet.theme(dayTheme))
        reader.appearance.waitUntil(\.label, equals: try style(theme: dayTheme))
        sheet.choose(sheet.theme("night"))
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))
        XCUIDevice.shared.appearance = .light

        reader.appearance.waitUntil(\.label, equals: try style(theme: dayTheme))
        sheet.theme(dayTheme).waitUntil(\.isSelected, equals: true)
    }

    private func launchWithRotationLock() throws -> XCUIApplication {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .phone, "Rotation lock is iPhone only")
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.orientation = .portrait
        }
        return launchWithGermanBook()
    }

    private func launchWithGermanBook() -> XCUIApplication {
        launch(germanBook)
    }

    private func relaunch() -> XCUIApplication {
        launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil, notificationPermission: nil))
    }

    private func scrollDown(_ app: XCUIApplication) {
        for _ in 1...3 {
            app.swipeUp()
        }
    }

    private func percent(_ page: Int, of pages: Int) -> String {
        (Double(page) / Double(pages)).formatted(.percent.precision(.fractionLength(0)))
    }

    private func sizeValue(_ step: Int) -> String {
        "\(step) of 7"
    }

    private func style(theme: String) throws -> String {
        try style(theme: theme, family: "Literata", step: defaultStep, spacing: \.normal, pageTurn: "slide")
    }

    private func style(family: String) throws -> String {
        try style(theme: "paper", family: family, step: defaultStep, spacing: \.normal, pageTurn: "slide")
    }

    private func style(step: Int) throws -> String {
        try style(theme: "paper", family: "Literata", step: step, spacing: \.normal, pageTurn: "slide")
    }

    private func style(spacing: KeyPath<ReadingStep, Int>) throws -> String {
        try style(theme: "paper", family: "Literata", step: defaultStep, spacing: spacing, pageTurn: "slide")
    }

    private func style(pageTurn: String) throws -> String {
        try style(theme: "paper", family: "Literata", step: defaultStep, spacing: \.normal, pageTurn: pageTurn)
    }

    private func style(
        theme: String, family: String, step: Int, spacing: KeyPath<ReadingStep, Int>, pageTurn: String
    ) throws -> String {
        let tokens = try TokenValues.load()
        let colors: (page: RGB, text: RGB) =
            switch theme {
            case "sepia": (try tokens.color("surface-sepia", dark: false), try tokens.color("sepia-text", dark: false))
            case "night": (try tokens.color("surface-paper", dark: true), try tokens.color("night-text", dark: true))
            case "black": (try tokens.color("surface-black", dark: true), try tokens.color("night-text", dark: true))
            default: (try tokens.color("surface-paper", dark: false), try tokens.color("ink", dark: false))
            }
        let size = try tokens.readingScale()[step - 1]
        return
            "\(colors.page) · \(colors.text) · \(family) · \(size.fontSize)/\(size[keyPath: spacing]) · \(pageTurn)"
    }
}

private struct Span {
    let chapter: Int
    let start: Int
    let end: Int

    func contains(_ offset: Int) -> Bool {
        start <= offset && offset < end
    }
}

private func span(in value: String?) -> Span? {
    guard let match = value?.wholeMatch(of: /(\d+):(\d+)-(\d+)/)?.output,
        let chapter = Int(match.1), let start = Int(match.2), let end = Int(match.3)
    else {
        return nil
    }
    return Span(chapter: chapter, start: start, end: end)
}

private func number(in counter: String) -> Int {
    Int(counter.components(separatedBy: " of ").first ?? "") ?? 0
}

private func total(in counter: String) -> Int {
    Int(counter.components(separatedBy: " of ").last ?? "") ?? 0
}
