import XCTest

extension XCUIElement {
    var isOn: Bool {
        value as? String == "1"
    }
}
