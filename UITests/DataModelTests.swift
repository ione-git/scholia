import XCTest

final class DataModelTests: UITestCase {
    func testFixtureLibraryIsSeededAndSurvivesRelaunch() {
        let library = """
            Corrupted · no author · en · corrupted.epub
            Die Verwandlung · Franz Kafka · de · german.epub
            Encrypted · Franz Kafka · de · drm.epub
            Minimal · no author · en · minimal-metadata.epub
            Un matin en ville · Scholia · fr · french-no-cover.epub
            """
        let seeded = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata, .corrupted, .drm], opened: [],
                inProgress: [], highlighted: [],
                translation: .immediate, now: nil, notificationPermission: nil))
        HomeScreen(app: seeded).waitUntilShown().storedLibrary.waitUntil(\.label, equals: library)
        seeded.terminate()

        let relaunched = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        HomeScreen(app: relaunched).waitUntilShown().storedLibrary.waitUntil(\.label, equals: library)
    }

    func testResetDropsStoredBooksAndFiles() {
        let first = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        HomeScreen(app: first).waitUntilShown().storedLibrary.waitUntil(
            \.label,
            equals: """
                Die Verwandlung · Franz Kafka · de · german.epub
                Un matin en ville · Scholia · fr · french-no-cover.epub
                """)
        first.terminate()

        let reset = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        HomeScreen(app: reset).waitUntilShown().storedLibrary.waitUntil(
            \.label, equals: "Die Verwandlung · Franz Kafka · de · german.epub")
    }

    func testSeedingAgainKeepsOneCopyOfEachBook() {
        let first = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        HomeScreen(app: first).waitUntilShown().storedLibrary.waitUntil(
            \.label, equals: "Die Verwandlung · Franz Kafka · de · german.epub")
        first.terminate()

        let again = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        HomeScreen(app: again).waitUntilShown().storedLibrary.waitUntil(
            \.label,
            equals: """
                Die Verwandlung · Franz Kafka · de · german.epub
                Un matin en ville · Scholia · fr · french-no-cover.epub
                """)
    }
}
