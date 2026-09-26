import SnapshotTesting
import XCTest

private let pixelPrecision: Float = 1
private let perceptualPrecision: Float = 0.98
private let settleTimeout: TimeInterval = 10

extension UITestCase {
    func assertSnapshot(
        of screen: some Screen, named name: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        screen.waitUntilShown(file: file, line: line)
        let image = settledScreenshot(of: screen.app, file: file, line: line)
        let failure = verifySnapshot(
            of: image,
            as: .image(precision: pixelPrecision, perceptualPrecision: perceptualPrecision),
            named: XCUIDevice.shared.appearance == .dark ? "dark" : "light",
            record: recordMode,
            file: file,
            testName: name
        )
        if let failure {
            XCTFail(failure, file: file, line: line)
        }
    }

    private var recordMode: SnapshotTestingConfiguration.Record {
        ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"]
            .flatMap(SnapshotTestingConfiguration.Record.init(rawValue:)) ?? .never
    }

    private func settledScreenshot(of app: XCUIApplication, file: StaticString, line: UInt) -> UIImage {
        let systemBars = systemBarInsets()
        var previous = screenshot(of: app, without: systemBars)
        let deadline = Date.now.addingTimeInterval(settleTimeout)
        while Date.now < deadline {
            let current = screenshot(of: app, without: systemBars)
            if current.pngData() == previous.pngData() {
                return current
            }
            previous = current
        }
        XCTFail("\(app.description) kept changing for \(settleTimeout) s", file: file, line: line)
        return previous
    }

    private func systemBarInsets() -> UIEdgeInsets {
        let statusBar = XCUIApplication(bundleIdentifier: "com.apple.springboard").statusBars.firstMatch
        let homeIndicator = UIApplication.shared.connectedScenes.compactMap { scene in
            (scene as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom
        }
        return UIEdgeInsets(
            top: statusBar.exists ? statusBar.frame.maxY : 0, left: 0, bottom: homeIndicator.first ?? 0, right: 0)
    }

    private func screenshot(of app: XCUIApplication, without systemBars: UIEdgeInsets) -> UIImage {
        let image = app.screenshot().image
        guard let full = image.cgImage else { return image }
        let bounds = CGRect(x: 0, y: 0, width: full.width, height: full.height)
        let content = bounds.inset(
            by: UIEdgeInsets(
                top: systemBars.top * image.scale, left: 0, bottom: systemBars.bottom * image.scale, right: 0))
        guard let cropped = full.cropping(to: content) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}
