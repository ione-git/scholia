import XCTest

final class HomeTests: UITestCase {
    func testFixtureLibraryShowsHeroAndRow() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [], inProgress: [],
                highlighted: [],
                translation: .immediate,
                now: nil, notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        XCTAssertEqual(home.heroAuthor.label, "Franz Kafka")
        XCTAssertEqual(home.heroCover.label, "Die Verwandlung")
        XCTAssertEqual(home.heroCover.frame.size, CGSize(width: 180, height: 270))
        XCTAssertEqual(home.heroProgress.value as? String, 0.0.formatted(.percent.precision(.fractionLength(0))))
        XCTAssertEqual(home.heroProgress.frame.width, 180)
        XCTAssertEqual(home.libraryButton.label, "Library, All 3")
        for title in ["Minimal", "Un matin en ville"] {
            let cover = home.book(title).waitUntilExists()
            XCTAssertEqual(cover.frame.width, 80, accuracy: 0.01)
            XCTAssertEqual(cover.frame.height, 120, accuracy: 0.01)
        }
        XCTAssertFalse(home.book("Die Verwandlung").exists)
    }

    func testSingleBookIsHeroWithEmptyRow() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.minimalMetadata], opened: [], inProgress: [], highlighted: [],
                translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.heroTitle.waitUntil(\.label, equals: "Minimal")
        XCTAssertFalse(home.heroAuthor.exists)
        XCTAssertEqual(home.libraryButton.label, "Library, All 1")
        XCTAssertFalse(home.book("Minimal").exists)
    }

    func testLibraryOpensFromHome() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.openLibrary().goBack()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
    }

    func testHeaderHasGoalRingAndGlassButtonsAndOpensSettings() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.goalRing.waitUntilExists()
        XCTAssertEqual(home.addBookButton.waitUntilExists().label, "Add a book")
        XCTAssertEqual(home.addBookButton.frame.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(home.settingsButton.label, "Settings")
        XCTAssertEqual(home.settingsButton.frame.size, CGSize(width: 44, height: 44))

        home.openSettings().goBack()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
    }

    func testMainSnapshotLight() throws {
        assertSnapshot(of: try homeAfterReading(minutesRead: 14, appearance: .light), named: "Main")
    }

    func testMainSnapshotDark() throws {
        assertSnapshot(of: try homeAfterReading(minutesRead: 14, appearance: .dark), named: "Main")
    }

    func testHomeDone3SnapshotLight() throws {
        assertSnapshot(of: try homeAfterReading(minutesRead: 23, appearance: .light), named: "Home-Done-3")
    }

    func testHomeDone3SnapshotDark() throws {
        assertSnapshot(of: try homeAfterReading(minutesRead: 23, appearance: .dark), named: "Home-Done-3")
    }

    private func homeAfterReading(minutesRead: Int, appearance: XCUIDevice.Appearance) throws -> HomeScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [], inProgress: [],
                highlighted: [], translation: .immediate, now: try Date("2026-03-14T12:00:00Z", strategy: .iso8601),
                notificationPermission: nil, minutesRead: minutesRead),
            appearance: appearance)
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.turnForward(expecting: "2 of 54")
        reader.turnForward(expecting: "3 of 54")
        let home = reader.backToHome()
        home.heroTimeLeft.waitUntilExists()
        return home
    }
}
