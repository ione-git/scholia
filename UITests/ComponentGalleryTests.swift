import XCTest

final class ComponentGalleryTests: UITestCase {
    func testComponentGalleryGlassButtonSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openGlassButtons(), named: "ComponentGallery-GlassButton")
    }

    func testComponentGalleryGlassButtonSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openGlassButtons(), named: "ComponentGallery-GlassButton")
    }

    func testComponentGalleryChipSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openChips(), named: "ComponentGallery-Chip")
    }

    func testComponentGalleryChipSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openChips(), named: "ComponentGallery-Chip")
    }

    func testComponentGalleryBookCoverSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openBookCovers(), named: "ComponentGallery-BookCover")
    }

    func testComponentGalleryBookCoverSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openBookCovers(), named: "ComponentGallery-BookCover")
    }

    func testComponentGalleryLargeBookCoverSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openLargeBookCovers(), named: "ComponentGallery-LargeBookCover")
    }

    func testComponentGalleryLargeBookCoverSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openLargeBookCovers(), named: "ComponentGallery-LargeBookCover")
    }

    func testComponentGalleryListRowsSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openListRows(), named: "ComponentGallery-ListRows")
    }

    func testComponentGalleryListRowsSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openListRows(), named: "ComponentGallery-ListRows")
    }

    func testComponentGalleryChapterRowsSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openChapterRows(), named: "ComponentGallery-ChapterRows")
    }

    func testComponentGalleryChapterRowsSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openChapterRows(), named: "ComponentGallery-ChapterRows")
    }

    func testComponentGalleryHighlightCardsSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openHighlightCards(), named: "ComponentGallery-HighlightCards")
    }

    func testComponentGalleryHighlightCardsSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openHighlightCards(), named: "ComponentGallery-HighlightCards")
    }

    func testComponentGallerySegmentedControlSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openSegmentedControls(), named: "ComponentGallery-SegmentedControl")
    }

    func testComponentGallerySegmentedControlSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openSegmentedControls(), named: "ComponentGallery-SegmentedControl")
    }

    func testComponentGalleryModalSheetSnapshotLight() {
        assertSnapshot(
            of: openGallery(.light).openPresentations().openModalSheet(), named: "ComponentGallery-ModalSheet")
    }

    func testComponentGalleryModalSheetSnapshotDark() {
        assertSnapshot(
            of: openGallery(.dark).openPresentations().openModalSheet(), named: "ComponentGallery-ModalSheet")
    }

    func testComponentGalleryGlassSheetSnapshotLight() {
        assertSnapshot(
            of: openGallery(.light).openPresentations().openGlassSheet(), named: "ComponentGallery-GlassSheet")
    }

    func testComponentGalleryGlassSheetSnapshotDark() {
        assertSnapshot(
            of: openGallery(.dark).openPresentations().openGlassSheet(), named: "ComponentGallery-GlassSheet")
    }

    func testComponentGalleryPopoverSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openPresentations().openPopover(), named: "ComponentGallery-Popover")
    }

    func testComponentGalleryPopoverSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openPresentations().openPopover(), named: "ComponentGallery-Popover")
    }

    func testComponentGallerySelectionSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openSelection(), named: "ComponentGallery-Selection")
    }

    func testComponentGallerySelectionSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openSelection(), named: "ComponentGallery-Selection")
    }

    func testComponentGalleryTranslationBubbleSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openTranslationBubbles(), named: "ComponentGallery-TranslationBubble")
    }

    func testComponentGalleryTranslationBubbleSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openTranslationBubbles(), named: "ComponentGallery-TranslationBubble")
    }

    func testComponentGalleryGlassMenuSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openGlassMenu(), named: "ComponentGallery-GlassMenu")
    }

    func testComponentGalleryGlassMenuSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openGlassMenu(), named: "ComponentGallery-GlassMenu")
    }

    func testComponentGalleryTranslationPillSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openTranslationPills(), named: "ComponentGallery-TranslationPill")
    }

    func testComponentGalleryTranslationPillSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openTranslationPills(), named: "ComponentGallery-TranslationPill")
    }

    func testComponentGalleryWordCardSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openWordCards(), named: "ComponentGallery-WordCard")
    }

    func testComponentGalleryWordCardSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openWordCards(), named: "ComponentGallery-WordCard")
    }

    func testComponentGallerySelectionMenuSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openSelectionMenu(), named: "ComponentGallery-SelectionMenu")
    }

    func testComponentGallerySelectionMenuSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openSelectionMenu(), named: "ComponentGallery-SelectionMenu")
    }

    func testComponentGalleryHighlightColorMenuSnapshotLight() {
        assertSnapshot(of: openGallery(.light).openHighlightColorMenu(), named: "ComponentGallery-HighlightColorMenu")
    }

    func testComponentGalleryHighlightColorMenuSnapshotDark() {
        assertSnapshot(of: openGallery(.dark).openHighlightColorMenu(), named: "ComponentGallery-HighlightColorMenu")
    }

    private func openGallery(_ appearance: XCUIDevice.Appearance) -> ComponentGalleryScreen {
        HomeScreen(app: launch(.withoutBooks, appearance: appearance)).waitUntilShown().openComponentGallery()
    }
}
