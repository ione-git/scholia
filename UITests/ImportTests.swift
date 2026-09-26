import XCTest

private let germanCover = RGBColor(red: 47, green: 74, blue: 58)

final class ImportTests: UITestCase {
    func testAddButtonOpensFilesPicker() {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
        let picker = HomeScreen(app: app).waitUntilShown().pickFile()
        attachScreenshot("FilePicker")

        let home = picker.cancel()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testImportEditTitleChangeLanguageAddsBookToLibrary() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)

        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")
        XCTAssertEqual(addBook.authorField.stringValue, "Franz Kafka")
        XCTAssertEqual(addBook.fileInfo.label, try Fixture.german.fileInfo)
        XCTAssertEqual(addBook.cover.frame.size, CGSize(width: 100, height: 150))
        let cover = try addBook.coverColor()
        XCTAssertTrue(cover.isClose(to: germanCover), "cover is \(cover), expected \(germanCover)")
        XCTAssertEqual(addBook.languageButton.label, "Language, German · detected")
        attachScreenshot("Import")

        try addBook.replaceTitle(with: "Die Verwandlung, Auszug")
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung, Auszug")
        XCTAssertEqual(addBook.cover.label, "Die Verwandlung, Auszug")
        try addBook.replaceAuthor(with: "F. Kafka")
        addBook.authorField.waitUntil(\.stringValue, equals: "F. Kafka")

        let picker = addBook.chooseLanguage()
        picker.language("de").waitUntil(\.isSelected, equals: true)
        XCTAssertEqual(picker.languages, ["de", "en", "fr", "es", "it", "pl", "pt", "nl"])
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
        XCTAssertEqual(home.heroAuthor.label, "F. Kafka")
        let heroCover = try home.heroCoverColor()
        XCTAssertTrue(heroCover.isClose(to: germanCover), "hero cover is \(heroCover), expected \(germanCover)")
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Die Verwandlung, Auszug · F. Kafka · fr · "), stored)
        XCTAssertTrue(stored.hasSuffix(".epub"), stored)
    }

    func testSearchFindsLanguageOutsideSuggestions() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
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
        XCTAssertEqual(reopened.languages, ["de", "en", "fr", "es", "it", "pl", "pt", "nl", "ja"])
    }

    func testSecondFileReplacesBookInSheet() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        addBook.titleField.waitUntil(\.stringValue, equals: "Die Verwandlung")

        try addBook.openFromOtherApp(.frenchNoCover)

        addBook.titleField.waitUntil(\.stringValue, equals: "Un matin en ville")
        XCTAssertEqual(addBook.authorField.stringValue, "Scholia")
        XCTAssertEqual(addBook.languageButton.label, "Language, French · detected")
        XCTAssertEqual(addBook.fileInfo.label, try Fixture.frenchNoCover.fileInfo)
        let home = addBook.add()
        home.heroTitle.waitUntil(\.label, equals: "Un matin en ville")
        let stored = home.storedLibrary.label
        XCTAssertTrue(stored.hasPrefix("Un matin en ville · Scholia · fr · "), stored)
        XCTAssertFalse(stored.contains("\n"), stored)
    }

    func testBrokenSecondFileKeepsBookInSheet() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
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
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
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
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
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
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.addButton.waitUntil(\.isEnabled, equals: true)

        try addBook.replaceTitle(with: " ")

        addBook.addButton.waitUntil(\.isEnabled, equals: false)
        try addBook.replaceTitle(with: "Un matin")
        addBook.addButton.waitUntil(\.isEnabled, equals: true)
    }

    func testCancelDiscardsBook() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover)
        addBook.titleField.waitUntil(\.stringValue, equals: "Un matin en ville")

        let home = addBook.cancel()

        home.storedLibrary.waitUntil(\.label, equals: "Die Verwandlung · Franz Kafka · de · german.epub")
        XCTAssertEqual(home.heroTitle.label, "Die Verwandlung")
    }

    func testBrokenFileShowsAlert() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
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
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
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
