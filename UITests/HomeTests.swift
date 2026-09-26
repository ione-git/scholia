import XCTest

final class HomeTests: UITestCase {
    func testFixtureLibraryShowsHeroAndRow() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [],
                mocksTranslation: true,
                now: nil, notificationPermission: nil, unreadableStore: false))
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
        attachScreenshot("Main")
    }

    func testSingleBookIsHeroWithEmptyRow() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.minimalMetadata], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: nil, unreadableStore: false))
        let home = HomeScreen(app: app).waitUntilShown()

        home.heroTitle.waitUntil(\.label, equals: "Minimal")
        XCTAssertFalse(home.heroAuthor.exists)
        XCTAssertEqual(home.libraryButton.label, "Library, All 1")
        XCTAssertFalse(home.book("Minimal").exists)
    }

    func testLibraryOpensFromHome() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: nil, unreadableStore: false))
        let home = HomeScreen(app: app).waitUntilShown()

        home.openLibrary().goBack()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
    }

    func testHeaderHasGoalRingAndGlassButtonsAndOpensSettings() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: nil, unreadableStore: false))
        let home = HomeScreen(app: app).waitUntilShown()

        XCTAssertEqual(home.goalRing.waitUntilExists().frame.size, CGSize(width: 28, height: 28))
        XCTAssertEqual(home.addBookButton.waitUntilExists().label, "Add a book")
        XCTAssertEqual(home.addBookButton.frame.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(home.settingsButton.label, "Settings")
        XCTAssertEqual(home.settingsButton.frame.size, CGSize(width: 44, height: 44))

        home.openSettings().goBack()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
    }
}
