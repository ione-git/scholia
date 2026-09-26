import XCTest

final class ImportTests: UITestCase {
    func testAddButtonOpensFilesPicker() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        XCTAssertEqual(home.addBookButton.waitUntilExists().label, "Add a book")

        home.pickFile().cancel()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testEditedTitleAuthorAndLanguageAreStored() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)

        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")
        XCTAssertEqual(addBook.authorField.stringValue, "Franz Kafka")
        XCTAssertEqual(addBook.languageButton.label, "Language, German · detected")

        try addBook.replaceTitle(with: "Die Verwandlung, Auszug")
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung, Auszug")
        try addBook.replaceAuthor(with: "F. Kafka")
        addBook.authorField.waitUntil(\.stringValue, equals: "F. Kafka")

        let picker = addBook.chooseLanguage()
        picker.language("de").waitUntil(\.isSelected, equals: true)
        picker.search("fren")
        picker.language("de").waitUntilGone()

        picker.choose("fr")

        addBook.languageButton.waitUntil(\.label, equals: "Language, French")
        let home = addBook.add()
        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung, Auszug")
        XCTAssertEqual(home.heroAuthor.label, "F. Kafka")
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Die Verwandlung, Auszug · F. Kafka · fr · "), stored)
        XCTAssertTrue(stored.hasSuffix(".epub"), stored)
    }

    func testSearchFindsLanguageOutsideSuggestions() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        let picker = addBook.chooseLanguage()
        picker.language("de").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(picker.language("ja").exists)

        picker.search("japan")
        picker.language("ja").waitUntil(\.label, equals: "Japanese")
        picker.choose("ja")

        addBook.languageButton.waitUntil(\.label, equals: "Language, Japanese")
        let reopened = addBook.chooseLanguage()
        reopened.language("ja").waitUntil(\.isSelected, equals: true)
    }

    func testSecondFileReplacesBookInSheet() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")

        try addBook.openFromOtherApp(.frenchNoCover)

        addBook.titleField.waitUntil(\.stringValue, equals: "Un matin en ville")
        XCTAssertEqual(addBook.authorField.stringValue, "Scholia")
        XCTAssertEqual(addBook.languageButton.label, "Language, French · detected")
        let home = addBook.add()
        home.heroTitle.waitUntil(\.label, equals: "Un matin en ville")
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Un matin en ville · Scholia · fr · "), stored)
        XCTAssertFalse(stored.contains("\n"), stored)
    }

    func testBrokenSecondFileKeepsBookInSheet() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")
        try addBook.replaceAuthor(with: "F. Kafka")
        addBook.authorField.waitUntil(\.stringValue, equals: "F. Kafka")

        let alert = try addBook.openUnreadableFromOtherApp(.corrupted)

        XCTAssertTrue(
            alert.messages.contains("“corrupted.epub” is damaged or is not an EPUB file."), "\(alert.messages)")
        alert.dismiss(to: addBook)
        XCTAssertEqual(addBook.titleField.stringValue, "Die Verwandlung")
        XCTAssertEqual(addBook.authorField.stringValue, "F. Kafka")
        let home = addBook.add()
        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Die Verwandlung · F. Kafka · de · "), stored)
    }

    func testBlankAuthorIsStoredWithoutAuthor() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.authorField.waitUntil(\.stringValue, equals: "Scholia")

        try addBook.replaceAuthor(with: " ")
        let home = addBook.add()

        home.heroTitle.waitUntil(\.label, equals: "Un matin en ville")
        XCTAssertFalse(home.heroAuthor.exists)
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Un matin en ville · no author · fr · "), stored)
    }

    func testBookWithoutAuthorIsStoredWithoutAuthor() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.minimalMetadata)

        addBook.titleField.waitUntil(\.stringValue, equals: "Minimal")
        XCTAssertEqual(addBook.authorField.stringValue, "")
        XCTAssertEqual(addBook.languageButton.label, "Language, English · detected")

        let home = addBook.add()

        home.heroTitle.waitUntil(\.label, equals: "Minimal")
        XCTAssertFalse(home.heroAuthor.exists)
        home.book("Die Verwandlung").waitUntilExists()
        XCTAssertTrue(home.storedLibrary.label.hasPrefix("Die Verwandlung · Franz Kafka · de · german.epub\n"))
        XCTAssertTrue(home.storedLibrary.label.contains("\nMinimal · no author · en · "))
    }

    func testEmptyTitleDisablesAdd() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.addButton.waitUntil(\.isEnabled, equals: true)

        try addBook.replaceTitle(with: " ")

        addBook.addButton.waitUntil(\.isEnabled, equals: false)
        try addBook.replaceTitle(with: "Un matin")
        addBook.addButton.waitUntil(\.isEnabled, equals: true)
    }

    func testCancelDiscardsBook() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.titleField.waitUntil(\.stringValue, equals: "Un matin en ville")

        let home = addBook.cancel()

        home.storedLibrary.waitUntil(\.label, equals: "Die Verwandlung · Franz Kafka · de · german.epub")
        XCTAssertEqual(home.heroTitle.label, "Die Verwandlung")
    }

    func testBrokenFileShowsAlert() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let alert = try HomeScreen(app: app).waitUntilShown().openUnreadableFromOtherApp(.corrupted)

        XCTAssertEqual(alert.root.label, "Can’t Add Book")
        XCTAssertTrue(
            alert.messages.contains("“corrupted.epub” is damaged or is not an EPUB file."), "\(alert.messages)")
        let home = alert.dismiss()

        XCTAssertFalse(AddBookScreen(app: app).root.exists)
        XCTAssertEqual(home.storedLibrary.label, "")
    }

    func testProtectedFileShowsAlert() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let alert = try HomeScreen(app: app).waitUntilShown().openUnreadableFromOtherApp(.drm)

        XCTAssertEqual(alert.root.label, "Can’t Add Book")
        XCTAssertTrue(
            alert.messages.contains("“drm.epub” is protected by DRM. Scholia can open only DRM-free books."),
            "\(alert.messages)")
        let home = alert.dismiss()

        XCTAssertFalse(AddBookScreen(app: app).root.exists)
        XCTAssertEqual(home.storedLibrary.label, "")
    }

    func testImportSnapshotLight() throws {
        assertSnapshot(of: try openGerman(appearance: .light), named: "Import")
    }

    func testImportSnapshotDark() throws {
        assertSnapshot(of: try openGerman(appearance: .dark), named: "Import")
    }

    func testImportLanguageSnapshotLight() throws {
        assertSnapshot(of: try openLanguagePicker(appearance: .light), named: "Import-Language")
    }

    func testImportLanguageSnapshotDark() throws {
        assertSnapshot(of: try openLanguagePicker(appearance: .dark), named: "Import-Language")
    }

    private func openGerman(appearance: XCUIDevice.Appearance) throws -> AddBookScreen {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.now = try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        let addBook = try HomeScreen(app: launch(configuration, appearance: appearance)).waitUntilShown()
            .openFromOtherApp(.german)
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")
        return addBook
    }

    private func openLanguagePicker(appearance: XCUIDevice.Appearance) throws -> LanguagePickerScreen {
        let picker = try openGerman(appearance: appearance).chooseLanguage()
        picker.language("de").waitUntil(\.isSelected, equals: true)
        return picker
    }
}
