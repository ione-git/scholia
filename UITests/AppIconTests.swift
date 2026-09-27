import XCTest

private let iconImage = CGRect(x: 2, y: 2, width: 64, height: 64)
private let clipInset: CGFloat = 1
private let clipCornerRadius: CGFloat = 17

final class AppIconTests: UITestCase {
    func testIconV1SnapshotLight() {
        let springboard = showHomeScreen(.light).customizeIcons("Default")
        assertSnapshot(of: springboard.scrollToAppIcon(), clippedTo: iconClip, named: "Icon-V1")
    }

    func testIconV1SnapshotDark() {
        let springboard = showHomeScreen(.dark)
        springboard.customizeIcons("Dark", springboard.mode("Always"))
        assertSnapshot(of: springboard.scrollToAppIcon(), clippedTo: iconClip, named: "Icon-V1")
    }

    private var iconClip: CGPath {
        CGPath(
            roundedRect: iconImage.insetBy(dx: clipInset, dy: clipInset), cornerWidth: clipCornerRadius,
            cornerHeight: clipCornerRadius, transform: nil)
    }

    private func showHomeScreen(_ appearance: XCUIDevice.Appearance) -> SpringboardScreen {
        addTeardownBlock { @MainActor in
            SpringboardScreen().customizeIcons("Default")
        }
        HomeScreen(app: launch(.withoutBooks, appearance: appearance)).waitUntilShown()
        XCUIDevice.shared.press(.home)
        return SpringboardScreen().waitUntilShown()
    }
}
