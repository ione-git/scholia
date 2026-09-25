#if DEBUG
    import SwiftUI
    import UserNotifications

    struct ReminderDiagnostics: View {
        @State private var permission: String?
        @State private var reminders = ""

        var body: some View {
            Color.clear
                .overlay {
                    if let permission {
                        Color.clear
                            .accessibilityElement()
                            .accessibilityIdentifier("debug.readingReminder")
                            .accessibilityLabel(Text(verbatim: reminders))
                            .accessibilityValue(Text(verbatim: permission))
                    }
                }
                .task {
                    while !Task.isCancelled {
                        await refresh()
                        try? await Task.sleep(for: .milliseconds(200))
                    }
                }
        }

        private func refresh() async {
            let center = UNUserNotificationCenter.current()
            let requests = await center.pendingNotificationRequests()
            reminders = requests.isEmpty ? "none" : requests.map(Self.summary).joined(separator: "\n")
            permission = Self.name(of: await center.notificationSettings().authorizationStatus)
        }

        private static func summary(of request: UNNotificationRequest) -> String {
            var parts = [request.identifier, request.content.title, request.content.body]
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                parts.append(
                    [trigger.dateComponents.hour, trigger.dateComponents.minute].compactMap { $0 }
                        .map { String(format: "%02d", $0) }.joined(separator: ":"))
                parts.append(trigger.repeats ? "repeats" : "once")
            }
            return parts.joined(separator: " · ")
        }

        private static func name(of status: UNAuthorizationStatus) -> String {
            switch status {
            case .notDetermined: "notDetermined"
            case .denied: "denied"
            case .authorized: "authorized"
            case .provisional: "provisional"
            case .ephemeral: "ephemeral"
            @unknown default: "unknown"
            }
        }
    }
#endif
