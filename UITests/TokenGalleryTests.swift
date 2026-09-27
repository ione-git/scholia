import XCTest

final class TokenGalleryTests: UITestCase {
    func testTokenGalleryColoursSurfacesSnapshotLight() {
        assertSnapshot(of: openSection("coloursSurfaces", .light), named: "TokenGallery-Colours-Surfaces")
    }

    func testTokenGalleryColoursSurfacesSnapshotDark() {
        assertSnapshot(of: openSection("coloursSurfaces", .dark), named: "TokenGallery-Colours-Surfaces")
    }

    func testTokenGalleryColoursInkAndControlsSnapshotLight() {
        assertSnapshot(of: openSection("coloursInkAndControls", .light), named: "TokenGallery-Colours-InkAndControls")
    }

    func testTokenGalleryColoursInkAndControlsSnapshotDark() {
        assertSnapshot(of: openSection("coloursInkAndControls", .dark), named: "TokenGallery-Colours-InkAndControls")
    }

    func testTokenGalleryColoursHighlightsSnapshotLight() {
        assertSnapshot(of: openSection("coloursHighlights", .light), named: "TokenGallery-Colours-Highlights")
    }

    func testTokenGalleryColoursHighlightsSnapshotDark() {
        assertSnapshot(of: openSection("coloursHighlights", .dark), named: "TokenGallery-Colours-Highlights")
    }

    func testTokenGalleryColoursOtherSnapshotLight() {
        assertSnapshot(of: openSection("coloursOther", .light), named: "TokenGallery-Colours-Other")
    }

    func testTokenGalleryColoursOtherSnapshotDark() {
        assertSnapshot(of: openSection("coloursOther", .dark), named: "TokenGallery-Colours-Other")
    }

    func testTokenGalleryTextStylesSnapshotLight() {
        assertSnapshot(of: openSection("textStyles", .light), named: "TokenGallery-TextStyles")
    }

    func testTokenGalleryTextStylesSnapshotDark() {
        assertSnapshot(of: openSection("textStyles", .dark), named: "TokenGallery-TextStyles")
    }

    func testTokenGallerySpacingSnapshotLight() {
        assertSnapshot(of: openSection("spacing", .light), named: "TokenGallery-Spacing")
    }

    func testTokenGallerySpacingSnapshotDark() {
        assertSnapshot(of: openSection("spacing", .dark), named: "TokenGallery-Spacing")
    }

    func testTokenGalleryRadiusSnapshotLight() {
        assertSnapshot(of: openSection("radius", .light), named: "TokenGallery-Radius")
    }

    func testTokenGalleryRadiusSnapshotDark() {
        assertSnapshot(of: openSection("radius", .dark), named: "TokenGallery-Radius")
    }

    func testTokenGalleryShadowsSnapshotLight() {
        assertSnapshot(of: openSection("shadows", .light), named: "TokenGallery-Shadows")
    }

    func testTokenGalleryShadowsSnapshotDark() {
        assertSnapshot(of: openSection("shadows", .dark), named: "TokenGallery-Shadows")
    }

    func testTokenGalleryEffectsSnapshotLight() {
        assertSnapshot(of: openSection("effects", .light), named: "TokenGallery-Effects")
    }

    func testTokenGalleryEffectsSnapshotDark() {
        assertSnapshot(of: openSection("effects", .dark), named: "TokenGallery-Effects")
    }

    func testTokenGalleryReaderThemesSnapshotLight() {
        assertSnapshot(of: openSection("readerThemes", .light), named: "TokenGallery-ReaderThemes")
    }

    func testTokenGalleryReaderThemesSnapshotDark() {
        assertSnapshot(of: openSection("readerThemes", .dark), named: "TokenGallery-ReaderThemes")
    }

    private func openSection(_ section: String, _ appearance: XCUIDevice.Appearance) -> TokenGallerySectionScreen {
        HomeScreen(app: launch(.withoutBooks, appearance: appearance)).waitUntilShown().openTokenGallery()
            .open(section)
    }
}
