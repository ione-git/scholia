import XCTest

final class GoalTests: UITestCase {
    private let bookPages = 54
    private let arabicBookPages = 9
    private let noon = "2026-03-14T12:00:00Z"

    func testReadingAddsToTodayAndShowsTimeLeft() throws {
        let home = HomeScreen(app: launch(try threeBooks(minutesRead: 14))).waitUntilShown()
        XCTAssertEqual(home.goalRing.waitUntilExists().label, "Today: 14 of 20 minutes read")
        XCTAssertFalse(home.heroTimeLeft.exists)

        let reader = home.openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.backToHome()

        home.heroTimeLeft.waitUntil(\.label, equals: "5 hours, 57 minutes left")
        XCTAssertEqual(home.goalRing.label, "Today: 14 of 20 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(0.7))
        let goal = home.openGoal()
        XCTAssertEqual(goal.root.label, "Today: 14 minutes read, 6 minutes to go")
        goal.dismiss()
    }

    func testReachedGoalShowsDoneRingAndPopover() throws {
        let home = HomeScreen(app: launch(try threeBooks(minutesRead: 23))).waitUntilShown()
        let reader = home.openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        reader.backToHome()

        home.heroTimeLeft.waitUntil(\.label, equals: "9 hours, 47 minutes left")
        XCTAssertEqual(home.goalRing.label, "Today: goal reached, 23 minutes read")
        XCTAssertEqual(home.goalRing.value as? String, percent(1))
        let goal = home.openGoal()
        XCTAssertEqual(goal.root.label, "Today: goal done, 23 minutes read")
        goal.dismiss()
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
                resetsState: true, fixtures: [.arabic], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: try Date(noon, strategy: .iso8601), notificationPermission: nil,
                minutesRead: 2))
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

    func testHomeGoalSnapshotLight() throws {
        assertSnapshot(of: try openGoalAfterReading(minutesRead: 14, appearance: .light), named: "Home-Goal")
    }

    func testHomeGoalSnapshotDark() throws {
        assertSnapshot(of: try openGoalAfterReading(minutesRead: 14, appearance: .dark), named: "Home-Goal")
    }

    func testHomeDoneGoalSnapshotLight() throws {
        assertSnapshot(of: try openGoalAfterReading(minutesRead: 23, appearance: .light), named: "Home-Done-Goal")
    }

    func testHomeDoneGoalSnapshotDark() throws {
        assertSnapshot(of: try openGoalAfterReading(minutesRead: 23, appearance: .dark), named: "Home-Done-Goal")
    }

    private func launchWithGermanBook(now: Date?, minutesRead: Int) -> XCUIApplication {
        launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: now, notificationPermission: nil, minutesRead: minutesRead))
    }

    private func openGoalAfterReading(minutesRead: Int, appearance: XCUIDevice.Appearance) throws
        -> GoalPopoverScreen
    {
        let app = launch(try threeBooks(minutesRead: minutesRead), appearance: appearance)
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        let home = reader.backToHome()
        home.heroTimeLeft.waitUntilExists()
        return home.openGoal()
    }

    private func threeBooks(minutesRead: Int) throws -> LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [], inProgress: [],
            highlighted: [], translation: .immediate, now: try Date(noon, strategy: .iso8601),
            notificationPermission: nil,
            minutesRead: minutesRead)
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
