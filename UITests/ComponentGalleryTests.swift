import XCTest

final class ComponentGalleryTests: UITestCase {
    func testGalleryShowsEveryComponentInLightAndDark() {
        for appearance in [ComponentGalleryScreen.Appearance.light, .dark] {
            var gallery = openGallery().select(appearance)
            gallery.appearance(appearance).waitUntil(\.isSelected, equals: true)
            XCTAssertEqual(gallery.root.value as? String, appearance.rawValue)
            let suffix = appearance == .dark ? "-Dark" : ""

            let glassButtons = gallery.openGlassButtons()
            XCTAssertEqual(glassButtons.root.value as? String, appearance.rawValue)
            for element in ["back", "add", "bookmark", "menu", "readerBookmark", "readerMenu"] {
                glassButtons.button(element).waitUntilExists()
            }
            attachScreenshot("GlassButton\(suffix)")
            gallery = glassButtons.goBack()

            let chips = gallery.openChips()
            XCTAssertEqual(chips.root.value as? String, appearance.rawValue)
            for name in ["All", "Biographies", "Fiction"] {
                chips.chip(name).waitUntilExists()
            }
            chips.newCollection.waitUntilExists()
            attachScreenshot("Chip\(suffix)")
            gallery = chips.goBack()

            let covers = gallery.openBookCovers()
            XCTAssertEqual(covers.root.value as? String, appearance.rawValue)
            for title in ["Die Verwandlung", "Solaris", "Il nome della rosa", "Thumbnail", "Der Prozess", "Educated"] {
                covers.cover(title).waitUntilExists()
            }
            covers.cover("L’Étranger").waitUntilExists()
            covers.cover("Image").waitUntilExists()
            covers.progress.waitUntilExists()
            attachScreenshot("BookCover\(suffix)")
            gallery = covers.goBack()

            let rows = gallery.openListRows()
            XCTAssertEqual(rows.root.value as? String, appearance.rawValue)
            rows.translateTo.waitUntilExists()
            rows.onWordTap.waitUntilExists()
            rows.dailyGoal.waitUntilExists()
            attachScreenshot("ListRows\(suffix)")
            gallery = rows.goBack()

            let segmented = gallery.openSegmentedControls()
            XCTAssertEqual(segmented.root.value as? String, appearance.rawValue)
            for element in ["contents", "highlights", "bookmarks", "bubble", "minimal", "card"] {
                segmented.segment(element).waitUntilExists()
            }
            attachScreenshot("SegmentedControl\(suffix)")
            gallery = segmented.goBack()

            let presentations = gallery.openPresentations()
            XCTAssertEqual(presentations.root.value as? String, appearance.rawValue)
            let modal = presentations.openModalSheet()
            XCTAssertEqual(modal.root.value as? String, appearance.rawValue)
            attachScreenshot("ModalSheet\(suffix)")
            modal.cancel()
            let glass = presentations.openGlassSheet()
            XCTAssertEqual(glass.root.value as? String, appearance.rawValue)
            attachScreenshot("GlassSheet\(suffix)")
            glass.done()
            let popover = presentations.openPopover()
            XCTAssertEqual(popover.root.value as? String, appearance.rawValue)
            attachScreenshot("Popover\(suffix)")
        }
    }

    func testGlassButtonsHaveSpecSizesAndToggleOpenState() {
        let glassButtons = openGallery().openGlassButtons()
        for element in ["back", "add", "bookmark", "menu"] {
            XCTAssertEqual(glassButtons.button(element).waitUntilExists().frame.size, CGSize(width: 44, height: 44))
        }
        for element in ["readerBookmark", "readerMenu"] {
            XCTAssertEqual(glassButtons.button(element).waitUntilExists().frame.size, CGSize(width: 48, height: 48))
        }
        XCTAssertEqual(glassButtons.button("back").label, "Back")

        let menu = glassButtons.button("menu").waitUntil(\.isSelected, equals: true)
        menu.tap()
        menu.waitUntil(\.isSelected, equals: false)

        let readerMenu = glassButtons.button("readerMenu").waitUntil(\.isSelected, equals: false)
        readerMenu.tap()
        readerMenu.waitUntil(\.isSelected, equals: true)
    }

    func testChipSelectsOneCollectionAndNewChipAddsOne() {
        let chips = openGallery().openChips()
        XCTAssertEqual(chips.chip("All").waitUntilExists().frame.height, 36)
        XCTAssertEqual(chips.newCollection.waitUntilExists().frame.width, 36, accuracy: 0.01)
        XCTAssertEqual(chips.newCollection.frame.height, 36, accuracy: 0.01)
        XCTAssertEqual(chips.newCollection.label, "New collection")
        chips.chip("All").waitUntil(\.isSelected, equals: true)

        chips.chip("Biographies").waitUntilExists().tap()

        chips.chip("Biographies").waitUntil(\.isSelected, equals: true)
        chips.chip("All").waitUntil(\.isSelected, equals: false)

        chips.newCollection.tap()

        chips.chip("Collection 3").waitUntilExists()
    }

    func testBookCoversComeInEverySpecSize() {
        let covers = openGallery().openBookCovers()
        let expected = [
            "Thumbnail": CGSize(width: 40, height: 60),
            "Il nome della rosa": CGSize(width: 80, height: 120),
            "Educated": CGSize(width: 100, height: 150),
            "Solaris": CGSize(width: 107, height: 152),
            "Image": CGSize(width: 107, height: 152),
            "Die Verwandlung": CGSize(width: 160, height: 240),
            "Der Prozess": CGSize(width: 180, height: 270),
        ]
        let shown = Dictionary(
            uniqueKeysWithValues: expected.keys.map { ($0, covers.cover($0).waitUntilExists().frame.size) })
        XCTAssertEqual(shown, expected)
        XCTAssertEqual(covers.cover("L’Étranger").waitUntilExists().value as? String, "Finished")
        XCTAssertNotEqual(covers.cover("Solaris").value as? String, "Finished")
        XCTAssertEqual(
            covers.progress.waitUntilExists().value as? String, 0.4.formatted(.percent.precision(.fractionLength(0))))
        XCTAssertEqual(covers.progress.frame.width, 180)
    }

    func testListRowsHaveDesignHeights() {
        let rows = openGallery().openListRows()
        XCTAssertEqual(rows.translateTo.waitUntilExists().frame.height, 50)
        XCTAssertEqual(rows.onWordTap.waitUntilExists().frame.height, 56)
        XCTAssertEqual(rows.dailyGoal.waitUntilExists().frame.height, 50)
        XCTAssertEqual(rows.checkbox.waitUntilExists().frame.height, 50, accuracy: 0.5)
        XCTAssertEqual(rows.action.waitUntilExists().frame.height, 50, accuracy: 0.5)
        XCTAssertEqual(rows.action.label, "New Collection…")
        rows.segment("bubble").waitUntil(\.isSelected, equals: true)
        rows.checkbox.waitUntil(\.isSelected, equals: true)

        rows.segment("card").waitUntilExists().tap()
        rows.dailyGoal.tap()
        rows.checkbox.tap()

        rows.segment("card").waitUntil(\.isSelected, equals: true)
        rows.segment("bubble").waitUntil(\.isSelected, equals: false)
        rows.checkbox.waitUntil(\.isSelected, equals: false)
        XCTAssertTrue(rows.dailyGoal.label.contains("25 min"), rows.dailyGoal.label)
    }

    func testSegmentedControlSelectsOneSegment() {
        let segmented = openGallery().openSegmentedControls()
        XCTAssertEqual(segmented.segment("contents").waitUntilExists().frame.height, 36)
        XCTAssertEqual(segmented.segment("bubble").waitUntilExists().frame.height, 30)
        XCTAssertEqual(
            segmented.segment("contents").frame.width, segmented.segment("bookmarks").frame.width, accuracy: 0.5)
        segmented.segment("contents").waitUntil(\.isSelected, equals: true)

        segmented.segment("highlights").waitUntilExists().tap()

        segmented.segment("highlights").waitUntil(\.isSelected, equals: true)
        segmented.segment("contents").waitUntil(\.isSelected, equals: false)
        XCTAssertTrue(segmented.segment("highlights").label.contains("3"), segmented.segment("highlights").label)
    }

    func testSheetsAndPopoverOpenAndClose() {
        let presentations = openGallery().openPresentations()

        let modal = presentations.openModalSheet()
        modal.doneButton.waitUntilExists()
        presentations.modalSheetButton.waitUntilGone()
        modal.cancel()
        presentations.modalSheetButton.waitUntilExists()

        let glass = presentations.openGlassSheet()
        glass.select("curl")
        glass.segment("curl").waitUntil(\.isSelected, equals: true)
        glass.done()

        let popover = presentations.openPopover()
        XCTAssertEqual(popover.root.label, "6 min to go")
        popover.dismiss()
    }

    private func openGallery() -> ComponentGalleryScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: nil, unreadableStore: false))
        return HomeScreen(app: app).waitUntilShown().openComponentGallery()
    }

}
