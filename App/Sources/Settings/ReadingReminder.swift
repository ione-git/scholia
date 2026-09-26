import Foundation
import UserNotifications

enum ReadingReminder {
    enum Permission {
        case granted
        case declined
        case turnedOff
    }

    private static let identifier = "reading-reminder"
    private static var scheduling: Task<Void, Never>?

    static func requestPermission() async -> Permission {
        switch LaunchConfiguration.current.notificationPermission {
        case .authorized: return .granted
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

    static func schedule(for settings: Settings) {
        let time = settings.remindsDaily ? settings.reminderTime : nil
        let previous = scheduling
        previous?.cancel()
        scheduling = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            await replace(with: time)
        }
    }

    static func waitUntilScheduled() async {
        while let task = scheduling {
            await task.value
            if task == scheduling { return }
        }
    }

    private static func replace(with time: TimeOfDay?) async {
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
