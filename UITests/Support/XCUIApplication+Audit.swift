import XCTest

extension XCUIApplication {
    func auditAccessibilityOutsideTrackedIssues() throws {
        try performAccessibilityAudit(for: .all.subtracting([.dynamicType, .textClipped, .contrast])) { issue in
            issue.element?.identifier.hasPrefix("debug.") == true
        }
    }
}
