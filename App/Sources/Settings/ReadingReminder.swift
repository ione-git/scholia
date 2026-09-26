import Foundation
import UserNotifications

enum ReadingReminder {
    enum Permission {
        case granted
        case declined
        case turnedOff
    }

    private static let identifier = "reading-reminder"

    static func requestPermission() async -> Permission {
        switch LaunchConfiguration.current.notificationPermission {
        case .declined: return .declined
        case .denied: return .turnedOff
        case nil: break
        }
        let center = UNUserNotificationCenter.current()
        if await center.notificationSettings().authorizationStatus == .denied {
            return .turnedOff
        }
        let isGranted = try? await center.requestAuthorization(options: [.alert, .sound])
        return isGranted == true ? .granted : .declined
    }

    static func schedule(at time: TimeOfDay?) async {
        let center = UNUserNotificationCenter.current()
        guard let time else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to read")
        content.body = String(localized: "Pick up where you left off.")
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: time.hour, minute: time.minute), repeats: true)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
