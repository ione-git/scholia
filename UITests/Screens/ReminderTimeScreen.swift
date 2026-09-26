import XCTest

struct ReminderTimeScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.datePickers["reminderTime.picker"] }

    var minuteWheel: XCUIElement { root.pickerWheels.element(boundBy: 1) }

    var dismissRegion: XCUIElement { app.otherElements["PopoverDismissRegion"] }

    @discardableResult
    func setMinute(_ minute: String) -> Self {
        minuteWheel.waitUntilExists().adjust(toPickerWheelValue: minute)
        return self
    }

    @discardableResult
    func close() -> SettingsScreen {
        dismissRegion.waitUntilExists().tap()
        root.waitUntilGone()
        return SettingsScreen(app: app).waitUntilShown()
    }
}
