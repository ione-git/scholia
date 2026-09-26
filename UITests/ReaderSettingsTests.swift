import XCTest

final class ReaderSettingsTests: UITestCase {
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
        sheet.closeByTappingPage(reader)
        reader.hideChrome()
        attachScreenshot("Reader-Black")
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

        sheet.size.adjust(toNormalizedSliderPosition: 1)
        sheet.size.waitUntil(\.stringValue, equals: sizeValue(7))
        reader.appearance.waitUntil(\.label, equals: try style(step: 7))
        sheet.larger.waitUntil(\.isEnabled, equals: false)
        XCTAssertTrue(sheet.smaller.isEnabled)

        sheet.size.adjust(toNormalizedSliderPosition: 1.0 / 3)
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

    func testFadeTurnsPagesWithSwipes() {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()

        sheet.choose(sheet.pageTurn("fade"))
        XCTAssertFalse(sheet.pageTurn("slide").isSelected)
        sheet.closeByTappingPage(reader)

        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.turnBackward(expecting: "2 of \(bookPages)")
    }

    func testScrollAdvancesVerticallyAndReopensAtSamePlace() throws {
        let app = launchWithGermanBook()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        let sheet = reader.openSettings()

        sheet.choose(sheet.pageTurn("scroll"))
        reader.pageCounter.waitUntilGone()
        reader.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0) != nil })
        let top = try XCTUnwrap(span(in: reader.appearance.stringValue))
        sheet.closeByTappingPage(reader)
        reader.hideChrome()
        app.swipeUp()

        reader.appearance.waitUntil(\.stringValue, satisfies: { (span(in: $0)?.start ?? 0) > top.start })
        let scrolled = try XCTUnwrap(span(in: reader.appearance.stringValue))
        let reopened = reader.backToHome().openHeroBookInScrollMode()
        reopened.appearance.waitUntil(\.stringValue, satisfies: { span(in: $0)?.contains(scrolled.start) == true })
        XCTAssertFalse(reopened.pageCounter.exists)
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

    func testDarkAppearanceShowsNightForPaperAndPickedPaperStaysUntilAppearanceChanges() throws {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = .dark
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
        reader.appearance.waitUntil(\.label, equals: try style(theme: "night"))
        attachScreenshot("Reader-Dark")
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
        sheet.step(sheet.larger, expecting: sizeValue(4))
        sheet.step(sheet.larger, expecting: sizeValue(5))
        sheet.choose(sheet.lineSpacing("loose"))
        sheet.choose(sheet.pageTurn("fade"))
        sheet.setLockRotation(true)
        let changed = try style(theme: "sepia", family: "Charter", step: 5, spacing: \.loose)
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

    func testSettingsSheetScreenshotsInLightAndDark() {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        for appearance in [XCUIDevice.Appearance.light, .dark] {
            XCUIDevice.shared.appearance = appearance
            let app = launchWithGermanBook()
            let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
            let sheet = reader.openSettings()
            sheet.setLockRotation(true)
            sheet.theme(appearance == .dark ? "night" : "paper").waitUntil(\.isSelected, equals: true)
            attachScreenshot(appearance == .dark ? "Sheet-Dark" : "Reader-Menu-Settings")
            app.terminate()
        }
    }

    private func launchWithRotationLock() throws -> XCUIApplication {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .phone, "Rotation lock is iPhone only")
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.orientation = .portrait
        }
        return launchWithGermanBook()
    }

    private func launchWithGermanBook() -> XCUIApplication {
        launch(
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
    }

    private func relaunch() -> XCUIApplication {
        launch(LaunchConfiguration(resetsState: false, fixtures: [], opened: [], mocksTranslation: true, now: nil))
    }

    private func sizeValue(_ step: Int) -> String {
        "\(step) of 7"
    }

    private func style(theme: String) throws -> String {
        try style(theme: theme, family: "Literata", step: defaultStep, spacing: \.normal)
    }

    private func style(family: String) throws -> String {
        try style(theme: "paper", family: family, step: defaultStep, spacing: \.normal)
    }

    private func style(step: Int) throws -> String {
        try style(theme: "paper", family: "Literata", step: step, spacing: \.normal)
    }

    private func style(spacing: KeyPath<ReadingStep, Int>) throws -> String {
        try style(theme: "paper", family: "Literata", step: defaultStep, spacing: spacing)
    }

    private func style(theme: String, family: String, step: Int, spacing: KeyPath<ReadingStep, Int>) throws -> String {
        let tokens = try TokenValues.load()
        let colors: (page: RGB, text: RGB) =
            switch theme {
            case "sepia": (try tokens.color("surface-sepia", dark: false), try tokens.color("sepia-text", dark: false))
            case "night": (try tokens.color("surface-paper", dark: true), try tokens.color("night-text", dark: true))
            case "black": (try tokens.color("surface-black", dark: true), try tokens.color("night-text", dark: true))
            default: (try tokens.color("surface-paper", dark: false), try tokens.color("ink", dark: false))
            }
        let size = try tokens.readingScale()[step - 1]
        return "\(colors.page) · \(colors.text) · \(family) · \(size.fontSize)/\(size[keyPath: spacing])"
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

private func total(in counter: String) -> Int {
    Int(counter.components(separatedBy: " of ").last ?? "") ?? 0
}

extension HomeScreen {
    fileprivate func openHeroBookInScrollMode() -> ReaderScreen {
        heroCover.waitUntil(\.isHittable, equals: true).tap()
        return ReaderScreen(app: app).waitUntilShown()
    }
}
