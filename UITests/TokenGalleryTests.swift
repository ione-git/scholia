import XCTest

final class TokenGalleryTests: UITestCase {
    func testGalleryShowsEveryTokenInLightAndDark() throws {
        let gallery = openGallery()
        let tokens = try DesignTokens.load()
        var expected: [String] = []
        for token in tokens.color.tokens {
            expected += ["tokenGallery.lightSwatch.\(token.name)", "tokenGallery.darkSwatch.\(token.name)"]
        }
        expected += tokens.type.groups.flatMap(\.styles).map { "tokenGallery.textStyle.\($0.name)" }
        expected += tokens.spacing.tokens.map { "tokenGallery.spacing.\($0.name)" }
        expected += tokens.radius.tokens.map { "tokenGallery.radius.\($0.name)" }
        expected += tokens.shadow.tokens.map { "tokenGallery.shadow.\($0.name)" }
        expected += tokens.effects.tokens.map { "tokenGallery.effect.\($0.name)" }
        expected += ["paper", "sepia", "night", "black"].map { "tokenGallery.readerTheme.\($0)" }

        let shown = try gallery.shownElements()

        XCTAssertEqual(expected.filter { shown[$0] == nil }, [])
    }

    func testSerifStylesUseBundledLiterata() throws {
        let gallery = openGallery()
        let serifStyles = try DesignTokens.load().type.groups.filter { $0.family == "serif" }.flatMap(\.styles)

        let shown = try gallery.shownElements()

        XCTAssertFalse(serifStyles.isEmpty)
        for style in serifStyles {
            let fontName = try XCTUnwrap(shown["tokenGallery.textStyle.\(style.name)"], style.name)
            XCTAssertTrue(fontName.hasPrefix("Literata-Regular"), "\(style.name) uses \(fontName)")
        }
    }

    private func openGallery() -> TokenGalleryScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        return HomeScreen(app: app).waitUntilShown().openTokenGallery()
    }
}
