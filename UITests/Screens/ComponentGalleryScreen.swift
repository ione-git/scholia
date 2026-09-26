import XCTest

struct ComponentGalleryScreen: Screen {
    enum Appearance: String {
        case light
        case dark
    }

    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["componentGallery.scrollView"] }

    func appearance(_ appearance: Appearance) -> XCUIElement { app.buttons["componentGallery.\(appearance.rawValue)"] }

    @discardableResult
    func select(_ appearance: Appearance) -> Self {
        self.appearance(appearance).waitUntilExists().tap()
        return self
    }

    func open<Page: ComponentGalleryPage>(_ element: String, as page: (XCUIApplication) -> Page) -> Page {
        app.buttons["componentGallery.\(element)"].waitUntilExists().tap()
        return page(app).waitUntilShown().waitUntilSettled()
    }

    func openGlassButtons() -> GlassButtonGalleryScreen { open("glassButton", as: GlassButtonGalleryScreen.init) }
    func openChips() -> ChipGalleryScreen { open("chip", as: ChipGalleryScreen.init) }
    func openBookCovers() -> BookCoverGalleryScreen { open("bookCover", as: BookCoverGalleryScreen.init) }
    func openListRows() -> ListRowGalleryScreen { open("listRows", as: ListRowGalleryScreen.init) }
    func openSegmentedControls() -> SegmentedControlGalleryScreen {
        open("segmentedControl", as: SegmentedControlGalleryScreen.init)
    }
    func openPresentations() -> PresentationGalleryScreen { open("presentations", as: PresentationGalleryScreen.init) }
    func openGlassMenu() -> GlassMenuGalleryScreen { open("glassMenu", as: GlassMenuGalleryScreen.init) }
}

protocol ComponentGalleryPage: Screen {}

extension ComponentGalleryPage {
    func goBack() -> ComponentGalleryScreen {
        app.navigationBars.buttons["BackButton"].waitUntilExists().tap()
        return ComponentGalleryScreen(app: app).waitUntilShown().waitUntilSettled()
    }
}

struct GlassButtonGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["glassButtonGallery.scrollView"] }

    func button(_ element: String) -> XCUIElement { app.buttons["glassButtonGallery.\(element)"] }
    func text(_ element: String) -> XCUIElement { app.staticTexts["glassButtonGallery.\(element)"] }
}

struct GlassMenuGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["glassMenuGallery.scrollView"] }

    func item(_ element: String) -> XCUIElement { app.buttons["glassMenuGallery.\(element)"] }
}

struct ChipGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["chipGallery.scrollView"] }

    var newCollection: XCUIElement { app.buttons["chipGallery.newCollection"] }

    func chip(_ name: String) -> XCUIElement { app.buttons["chipGallery.chip.\(name)"] }
}

struct BookCoverGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["bookCoverGallery.scrollView"] }

    var progress: XCUIElement { app.descendants(matching: .any)["bookCoverGallery.progress"] }

    func cover(_ title: String) -> XCUIElement { app.descendants(matching: .any)["bookCoverGallery.cover.\(title)"] }
}

struct ListRowGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["listRowGallery.scrollView"] }

    var translateTo: XCUIElement { app.descendants(matching: .any)["listRowGallery.translateTo"] }
    var onWordTap: XCUIElement { app.descendants(matching: .any)["listRowGallery.onWordTap"] }
    var dailyGoal: XCUIElement { app.buttons["listRowGallery.dailyGoal"] }
    var checkbox: XCUIElement { app.buttons["listRowGallery.checkbox"] }
    var action: XCUIElement { app.buttons["listRowGallery.action"] }

    func segment(_ element: String) -> XCUIElement { app.buttons["listRowGallery.\(element)"] }
}

struct SegmentedControlGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["segmentedControlGallery.scrollView"] }

    func segment(_ element: String) -> XCUIElement { app.buttons["segmentedControlGallery.\(element)"] }
}

struct PresentationGalleryScreen: ComponentGalleryPage {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["presentationGallery.scrollView"] }

    var modalSheetButton: XCUIElement { app.buttons["presentationGallery.modalSheet"] }

    func openModalSheet() -> GalleryModalSheetScreen {
        modalSheetButton.waitUntilExists().tap()
        return GalleryModalSheetScreen(app: app).waitUntilShown()
    }

    func openGlassSheet() -> GalleryGlassSheetScreen {
        app.buttons["presentationGallery.glassSheet"].waitUntilExists().tap()
        return GalleryGlassSheetScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func openPopover() -> GalleryPopoverScreen {
        app.buttons["presentationGallery.popover"].waitUntilExists().tap()
        return GalleryPopoverScreen(app: app).waitUntilShown()
    }
}

struct GalleryModalSheetScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["galleryModalSheet.content"] }

    var cancelButton: XCUIElement { app.buttons["galleryModalSheet.cancel"] }
    var doneButton: XCUIElement { app.buttons["galleryModalSheet.done"] }

    @discardableResult
    func cancel() -> PresentationGalleryScreen {
        cancelButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return PresentationGalleryScreen(app: app).waitUntilShown()
    }
}

struct GalleryGlassSheetScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["galleryGlassSheet.content"] }

    var doneButton: XCUIElement { app.buttons["galleryGlassSheet.done"] }

    func segment(_ element: String) -> XCUIElement { app.buttons["galleryGlassSheet.\(element)"] }

    func select(_ element: String) {
        segment(element).waitUntil(\.isHittable, equals: true).tap()
    }

    @discardableResult
    func done() -> PresentationGalleryScreen {
        doneButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return PresentationGalleryScreen(app: app).waitUntilShown()
    }
}

struct GalleryPopoverScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["galleryPopover.text"] }

    @discardableResult
    func dismiss() -> PresentationGalleryScreen {
        PresentationGalleryScreen(app: app).root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        root.waitUntilGone()
        return PresentationGalleryScreen(app: app).waitUntilShown()
    }
}
