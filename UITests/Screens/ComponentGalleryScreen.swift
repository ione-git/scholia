import XCTest

struct ComponentGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["componentGallery.scrollView"] }

    func open<Page: Screen>(_ element: String, as page: (XCUIApplication) -> Page) -> Page {
        app.buttons["componentGallery.\(element)"].waitUntilExists().tap()
        return page(app).waitUntilShown().waitUntilSettled()
    }

    func openGlassButtons() -> GlassButtonGalleryScreen { open("glassButton", as: GlassButtonGalleryScreen.init) }
    func openChips() -> ChipGalleryScreen { open("chip", as: ChipGalleryScreen.init) }
    func openBookCovers() -> BookCoverGalleryScreen { open("bookCover", as: BookCoverGalleryScreen.init) }
    func openLargeBookCovers() -> LargeBookCoverGalleryScreen {
        open("largeBookCover", as: LargeBookCoverGalleryScreen.init)
    }
    func openListRows() -> ListRowGalleryScreen { open("listRows", as: ListRowGalleryScreen.init) }
    func openChapterRows() -> ChapterRowGalleryScreen { open("chapterRows", as: ChapterRowGalleryScreen.init) }
    func openSegmentedControls() -> SegmentedControlGalleryScreen {
        open("segmentedControl", as: SegmentedControlGalleryScreen.init)
    }
    func openPresentations() -> PresentationGalleryScreen { open("presentations", as: PresentationGalleryScreen.init) }
    func openSelection() -> SelectionGalleryScreen { open("selection", as: SelectionGalleryScreen.init) }
    func openTranslationBubbles() -> TranslationBubbleGalleryScreen {
        open("translationBubble", as: TranslationBubbleGalleryScreen.init)
    }
    func openGlassMenu() -> GlassMenuGalleryScreen { open("glassMenu", as: GlassMenuGalleryScreen.init) }
    func openTranslationPills() -> TranslationPillGalleryScreen {
        open("translationPill", as: TranslationPillGalleryScreen.init)
    }
    func openWordCards() -> WordCardGalleryScreen { open("wordCard", as: WordCardGalleryScreen.init) }
    func openSelectionMenu() -> SelectionMenuGalleryScreen {
        open("selectionMenu", as: SelectionMenuGalleryScreen.init)
    }
}

struct GlassButtonGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["glassButtonGallery.scrollView"] }
}

struct ChipGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["chipGallery.scrollView"] }
}

struct BookCoverGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["bookCoverGallery.scrollView"] }
}

struct LargeBookCoverGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["largeBookCoverGallery.scrollView"] }
}

struct ListRowGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["listRowGallery.scrollView"] }
}

struct ChapterRowGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["chapterRowGallery.scrollView"] }
}

struct SegmentedControlGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["segmentedControlGallery.scrollView"] }
}

struct SelectionGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["selectionGallery.scrollView"] }
}

struct TranslationBubbleGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["translationBubbleGallery.scrollView"] }
}

struct GlassMenuGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["glassMenuGallery.scrollView"] }
}

struct TranslationPillGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["translationPillGallery.scrollView"] }
}

struct WordCardGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["wordCardGallery.scrollView"] }
}

struct SelectionMenuGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["selectionMenuGallery.scrollView"] }
}

struct PresentationGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["presentationGallery.scrollView"] }

    func openModalSheet() -> GalleryModalSheetScreen {
        open("modalSheet", as: GalleryModalSheetScreen(app: app))
    }

    func openGlassSheet() -> GalleryGlassSheetScreen {
        open("glassSheet", as: GalleryGlassSheetScreen(app: app))
    }

    func openPopover() -> GalleryPopoverScreen {
        open("popover", as: GalleryPopoverScreen(app: app))
    }

    private func open<Presented: Screen>(_ element: String, as presented: Presented) -> Presented {
        app.buttons["presentationGallery.\(element)"].waitUntilExists().tap()
        presented.root.waitUntil(\.isHittable, equals: true)
        return presented
    }
}

struct GalleryModalSheetScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["galleryModalSheet.content"] }
}

struct GalleryGlassSheetScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["galleryGlassSheet.content"] }
}

struct GalleryPopoverScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["galleryPopover.text"] }
}
