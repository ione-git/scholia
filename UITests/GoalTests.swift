import XCTest

final class GoalTests: UITestCase {
    private let bookPages = 54
    private let arabicBookPages = 9
    private let noon = "2026-03-14T12:00:00Z"

    func testReadingAddsToTodayAndShowsTimeLeft() throws {
        let now = try Date(noon, strategy: .iso8601)
        setAppearance(.light)
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [],
                mocksTranslation: true, now: now, minutesRead: 14))
        let home = HomeScreen(app: app).waitUntilShown()
        XCTAssertEqual(home.goalRing.waitUntilExists().label, "Today: 14 of 20 minutes read")
        XCTAssertFalse(home.heroTimeLeft.exists)

        let reader = home.openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.backToHome()

        home.heroTimeLeft.waitUntil(\.label, equals: "5 hours, 57 minutes left")
        XCTAssertEqual(home.goalRing.label, "Today: 14 of 20 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(0.7))
        attachScreenshot("Main")
        let goal = home.openGoal()
        XCTAssertEqual(goal.root.label, "Today: 14 minutes read, 6 minutes to go")
        attachScreenshot("Home-Goal")
        goal.dismiss()
        app.terminate()

        setAppearance(.dark)
        let dark = relaunch(now: now)
        dark.heroTimeLeft.waitUntil(\.label, equals: "5 hours, 57 minutes left")
        XCTAssertEqual(dark.goalRing.label, "Today: 14 of 20 minutes read")
        attachScreenshot("Main-Dark")
        XCTAssertEqual(dark.openGoal().root.label, "Today: 14 minutes read, 6 minutes to go")
        attachScreenshot("Home-Goal-Dark")
    }

    func testReachedGoalShowsDoneRingAndPopover() throws {
        let now = try Date(noon, strategy: .iso8601)
        setAppearance(.light)
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [],
                mocksTranslation: true, now: now, minutesRead: 23))
        let home = HomeScreen(app: app).waitUntilShown()
        let reader = home.openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.backToHome()

        home.heroTimeLeft.waitUntil(\.label, equals: "9 hours, 47 minutes left")
        XCTAssertEqual(home.goalRing.label, "Today: goal reached, 23 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(1))
        attachScreenshot("Home-Done-3")
        let goal = home.openGoal()
        XCTAssertEqual(goal.root.label, "Today: goal done, 23 minutes read")
        attachScreenshot("Home-Done-Goal")
        goal.dismiss()
        app.terminate()

        setAppearance(.dark)
        let dark = relaunch(now: now)
        dark.heroTimeLeft.waitUntil(\.label, equals: "9 hours, 47 minutes left")
        XCTAssertEqual(dark.goalRing.label, "Today: goal reached, 23 minutes read")
        attachScreenshot("Home-Done-3-Dark")
        XCTAssertEqual(dark.openGoal().root.label, "Today: goal done, 23 minutes read")
        attachScreenshot("Home-Done-Goal-Dark")
    }

    func testChangingGoalInSettingsUpdatesRingAndPopover() throws {
        let home = HomeScreen(app: launchWithGermanBook(now: try Date(noon, strategy: .iso8601), minutesRead: 14))
            .waitUntilShown()

        let settings = home.openSettings()
        settings.chooseDailyGoal(10)
        settings.goBack()

        home.goalRing.waitUntil(\.label, equals: "Today: goal reached, 14 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(1))
        let done = home.openGoal()
        XCTAssertEqual(done.root.label, "Today: goal done, 14 minutes read")
        done.dismiss()

        let changed = home.openSettings()
        changed.chooseDailyGoal(15)
        changed.goBack()

        home.goalRing.waitUntil(\.label, equals: "Today: 14 of 15 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(14.0 / 15))
        XCTAssertEqual(home.openGoal().root.label, "Today: 14 minutes read, 1 minute to go")
    }

    func testOnlyTodaysPartOfSessionCountsAfterMidnight() throws {
        let home = HomeScreen(
            app: launchWithGermanBook(now: try Date("2026-03-14T00:05:00Z", strategy: .iso8601), minutesRead: 14)
        )
        .waitUntilShown()

        XCTAssertEqual(home.goalRing.waitUntilExists().label, "Today: 5 of 20 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(0.25))
        XCTAssertEqual(home.openGoal().root.label, "Today: 5 minutes read, 15 minutes to go")
    }

    func testTimeLeftForRightToLeftBook() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.arabic], opened: [], mocksTranslation: true,
                now: try Date(noon, strategy: .iso8601), minutesRead: 2))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(arabicBookPages)")
        reader.turnForwardRightToLeft(expecting: "2 of \(arabicBookPages)")
        reader.turnForwardRightToLeft(expecting: "3 of \(arabicBookPages)")

        reader.backToHome().heroTimeLeft.waitUntil(\.label, equals: "6 minutes left")
    }

    func testReaderRecordsSessionWithForwardPageTurns() throws {
        let app = launchWithGermanBook(now: nil, minutesRead: 0)
        let home = HomeScreen(app: app).waitUntilShown()

        let reader = home.openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.turnBackward(expecting: "2 of \(bookPages)")
        reader.backToHome()

        home.readingSessions.waitUntil(\.lineCount, equals: 1)
        let sessions = try sessions(in: home.readingSessions.label)
        XCTAssertEqual(sessions.map(\.pages), [2])
        XCTAssertGreaterThan(sessions[0].end, sessions[0].start)
    }

    func testGoingToBackgroundEndsSession() throws {
        let app = launchWithGermanBook(now: nil, minutesRead: 0)
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")

        XCUIDevice.shared.press(.home)
        SpringboardScreen().waitUntilShown()
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let home = reader.waitUntilOpened().backToHome()

        home.readingSessions.waitUntil(\.lineCount, equals: 2)
        let sessions = try sessions(in: home.readingSessions.label)
        XCTAssertEqual(sessions.map(\.pages), [1, 0])
        XCTAssertLessThanOrEqual(sessions[0].end, sessions[1].start)
        XCTAssertGreaterThan(sessions[1].end, sessions[1].start)
    }

    private func launchWithGermanBook(now: Date?, minutesRead: Int) -> XCUIApplication {
        launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: now,
                minutesRead: minutesRead))
    }

    private func relaunch(now: Date) -> HomeScreen {
        let app = launch(
            LaunchConfiguration(resetsState: false, fixtures: [], opened: [], mocksTranslation: true, now: now))
        return HomeScreen(app: app).waitUntilShown()
    }

    private func setAppearance(_ appearance: XCUIDevice.Appearance) {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = appearance
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private func sessions(in label: String) throws -> [Session] {
        let format = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        return try label.split(separator: "\n").map { line in
            let parts = line.split(separator: " · ")
            let times = parts[0].components(separatedBy: " – ")
            return Session(
                start: try format.parse(times[0]), end: try format.parse(times[1]),
                pages: try XCTUnwrap(Int(parts[1].split(separator: " ")[0])))
        }
    }
}

extension XCUIElement {
    fileprivate var lineCount: Int { label.split(separator: "\n").count }
}

private struct Session {
    let start: Date
    let end: Date
    let pages: Int
}
