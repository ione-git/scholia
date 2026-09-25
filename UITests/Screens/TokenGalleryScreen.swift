import XCTest

struct TokenGalleryScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.scrollViews["tokenGallery.scrollView"] }

    func shownElements() throws -> [String: String] {
        var values: [String: String] = [:]
        var pending = [try root.snapshot()]
        while let snapshot = pending.popLast() {
            values[snapshot.identifier] = snapshot.value as? String ?? ""
            pending += snapshot.children
        }
        return values
    }
}
