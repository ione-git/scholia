import XCTest

final class PrivacyManifestTests: UITestCase {
    func testAppBundleDeclaresRequiredReasonAPIs() {
        let app = launch(.withoutBooks)
        let home = HomeScreen(app: app).waitUntilShown()

        home.privacyManifest.waitUntil(
            \.label,
            equals: """
                NSPrivacyAccessedAPICategoryFileTimestamp · C617.1
                NSPrivacyAccessedAPICategoryUserDefaults · CA92.1
                """)
        XCTAssertEqual(
            home.privacyManifest.value as? String, "tracking false · 0 tracking domains · 0 collected data types")
    }
}
