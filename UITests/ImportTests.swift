import XCTest

final class ImportTests: UITestCase {
    func testAddButtonOpensFilesPicker() {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [.german], mocksTranslation: true, now: nil))
        let picker = HomeScreen(app: app).waitUntilShown().pickFile()
        attachScreenshot("FilePicker")

        let home = picker.cancel()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testImportEditTitleChangeLanguageAddsBookToLibrary() throws {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)

        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")
        XCTAssertEqual(addBook.authorField.stringValue, "Franz Kafka")
        XCTAssertEqual(addBook.fileInfo.label, try Fixture.german.fileInfo)
        XCTAssertEqual(addBook.cover.frame.size, CGSize(width: 100, height: 150))
        XCTAssertEqual(addBook.languageButton.label, "Language, German · detected")
        attachScreenshot("Import")

        try addBook.replaceTitle(with: "Die Verwandlung, Auszug")
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung, Auszug")
        XCTAssertEqual(addBook.cover.label, "Die Verwandlung, Auszug")

        let picker = addBook.chooseLanguage()
        picker.language("de").waitUntil(\.isSelected, equals: true)
        XCTAssertEqual(picker.language("de").label, "German · detected")
        XCTAssertFalse(picker.language("fr").isSelected)
        attachScreenshot("Import-Language")
        picker.search("fren")
        picker.language("de").waitUntilGone()
        XCTAssertEqual(picker.language("fr").label, "French")

        picker.choose("fr")

        addBook.languageButton.waitUntil(\.label, equals: "Language, French")
        let home = addBook.add()
        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung, Auszug")
        XCTAssertEqual(home.heroAuthor.label, "Franz Kafka")
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Die Verwandlung, Auszug · Franz Kafka · fr · "), stored)
        XCTAssertTrue(stored.hasSuffix(".epub"), stored)
    }

    func testBookWithoutAuthorIsStoredWithoutAuthor() throws {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [.german], mocksTranslation: true, now: nil))
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
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.addButton.waitUntil(\.isEnabled, equals: true)

        try addBook.replaceTitle(with: " ")

        addBook.addButton.waitUntil(\.isEnabled, equals: false)
        try addBook.replaceTitle(with: "Un matin")
        addBook.addButton.waitUntil(\.isEnabled, equals: true)
    }

    func testCancelDiscardsBook() throws {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [.german], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.titleField.waitUntil(\.stringValue, equals: "Un matin en ville")

        let home = addBook.cancel()

        home.storedLibrary.waitUntil(\.label, equals: "Die Verwandlung · Franz Kafka · de · german.epub")
        XCTAssertEqual(home.heroTitle.label, "Die Verwandlung")
    }

    func testBrokenFileShowsAlert() throws {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        let alert = try HomeScreen(app: app).waitUntilShown().openUnreadableFromOtherApp(.corrupted)

        XCTAssertEqual(alert.root.label, "Can’t Add Book")
        XCTAssertTrue(
            alert.messages.contains("“corrupted.epub” is damaged or is not an EPUB file."), "\(alert.messages)")
        let home = alert.dismiss()

        XCTAssertFalse(AddBookScreen(app: app).root.exists)
        XCTAssertEqual(home.storedLibrary.label, "")
    }

    func testProtectedFileShowsAlert() throws {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        let alert = try HomeScreen(app: app).waitUntilShown().openUnreadableFromOtherApp(.drm)

        XCTAssertEqual(alert.root.label, "Can’t Add Book")
        XCTAssertTrue(
            alert.messages.contains("“drm.epub” is protected by DRM. Scholia can open only DRM-free books."),
            "\(alert.messages)")
        let home = alert.dismiss()

        XCTAssertFalse(AddBookScreen(app: app).root.exists)
        XCTAssertEqual(home.storedLibrary.label, "")
    }
}
