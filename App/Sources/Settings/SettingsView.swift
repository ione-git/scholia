import DesignSystem
import SwiftData
import SwiftUI

struct SettingsView: View {
    private static let goalOptions = [5, 10, 15, 20, 30, 45, 60]
    private static let sortOrders: [LibrarySort] = [.recentlyOpened, .recentlyAdded, .title, .author]

    @Environment(Settings.self) private var settings
    @Environment(TranslationService.self) private var translationService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @State private var isTimePickerShown = false
    @State private var isAskingPermission = false
    @State private var isNotificationsOffAlertShown = false
    @State private var targetLanguages: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: .space6) {
                header
                translation
                reading
                appearance
                library
                Text("Scholia \(version)")
                    .textStyle(.caption)
                    .foregroundStyle(.inkMuted)
                    .accessibilityIdentifier("settings.version")
            }
            .padding(.horizontal, .space5)
            .padding(.bottom, .space10)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.surface)
        .toolbar(.hidden, for: .navigationBar)
        .task { targetLanguages = await translationService.provider.targetLanguages() }
    }

    private var header: some View {
        ZStack {
            Text("Settings")
                .textStyle(.section)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("settings.title")
            HStack {
                GlassButton(.back, label: Text("Back to Home"), size: .regular, isActive: false) { dismiss() }
                    .accessibilityIdentifier("settings.back")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .controlH)
    }

    private var translation: some View {
        GroupedSection(Text("Translation")) {
            Menu {
                Picker(selection: binding(\.translationLanguage)) {
                    ForEach(languages, id: \.self) { identifier in
                        Text(languageName(identifier))
                            .accessibilityIdentifier("settings.translateTo.\(identifier)")
                            .tag(identifier)
                    }
                } label: {
                    Text("Translate to")
                }
            } label: {
                ListRow(Text("Translate to"), height: .regular) {
                    ListRowValue(Text(languageName(settings.translationLanguage)))
                }
            }
            .accessibilityIdentifier("settings.translateTo")
            ListRow(Text("On word tap"), height: .control) {
                SegmentedControl(
                    selection: binding(\.wordTapStyle), size: .compact,
                    segments: [
                        .init(.bubble, title: Text("Bubble"), count: nil, identifier: "settings.onWordTap.bubble"),
                        .init(.minimal, title: Text("Minimal"), count: nil, identifier: "settings.onWordTap.minimal"),
                        .init(.card, title: Text("Card"), count: nil, identifier: "settings.onWordTap.card"),
                    ])
            }
        }
    }

    private var reading: some View {
        GroupedSection(Text("Reading")) {
            Menu {
                Picker(selection: binding(\.dailyGoalMinutes)) {
                    ForEach(Self.goalOptions, id: \.self) { minutes in
                        Text("\(minutes) min")
                            .accessibilityIdentifier("settings.dailyGoal.\(minutes)")
                            .tag(minutes)
                    }
                } label: {
                    Text("Daily goal")
                }
            } label: {
                ListRow(Text("Daily goal"), height: .regular) {
                    ListRowValue(Text("\(settings.dailyGoalMinutes) min"))
                }
            }
            .accessibilityIdentifier("settings.dailyGoal")
            HStack(spacing: .space3) {
                Button {
                    isTimePickerShown = true
                } label: {
                    ListRow(Text("Reminder at \(reminderTime, format: .dateTime.hour().minute())"), height: .regular) {}
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.reminderTime")
                .popover(isPresented: $isTimePickerShown) { timePicker }
                Toggle(isOn: reminderBinding) {
                    Text("Reminder")
                }
                .labelsHidden()
                .tint(.accent)
                .accessibilityIdentifier("settings.reminder")
            }
            .task(id: isAskingPermission) {
                if isAskingPermission {
                    await turnOnReminder()
                }
            }
            .alert(Text("Notifications are off"), isPresented: $isNotificationsOffAlertShown) {
                Button("Not Now", role: .cancel) {}
                    .accessibilityIdentifier("notificationsOff.notNow")
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
                .accessibilityIdentifier("notificationsOff.openSettings")
            } message: {
                Text("Allow notifications for Scholia in Settings to get a daily reminder.")
            }
        }
    }

    private var timePicker: some View {
        DatePicker(selection: reminderTimeBinding, displayedComponents: .hourAndMinute) {
            Text("Reminder time")
        }
        .datePickerStyle(.wheel)
        .labelsHidden()
        .accessibilityIdentifier("reminderTime.picker")
        .padding(.horizontal, .space4)
        .popoverStyle()
    }

    private var appearance: some View {
        GroupedSection(Text("Appearance")) {
            ListRow(Text("Theme"), height: .control) {
                SegmentedControl(
                    selection: binding(\.appTheme), size: .compact,
                    segments: [
                        .init(.system, title: Text("System"), count: nil, identifier: "settings.theme.system"),
                        .init(.light, title: Text("Light"), count: nil, identifier: "settings.theme.light"),
                        .init(.dark, title: Text("Dark"), count: nil, identifier: "settings.theme.dark"),
                    ])
            }
        }
    }

    private var library: some View {
        GroupedSection(Text("Library")) {
            Menu {
                Picker(selection: binding(\.librarySort)) {
                    ForEach(Self.sortOrders, id: \.self) { order in
                        Text(order.title)
                            .accessibilityIdentifier("settings.sortBooks.\(order.rawValue)")
                            .tag(order)
                    }
                } label: {
                    Text("Sort books by")
                }
            } label: {
                ListRow(Text("Sort books by"), height: .regular) {
                    ListRowValue(Text(settings.librarySort.title))
                }
            }
            .accessibilityIdentifier("settings.sortBooks")
        }
    }

    private var languages: [String] {
        targetLanguages.sorted {
            languageName($0).localizedStandardCompare(languageName($1)) == .orderedAscending
        }
    }

    private var reminderTime: Date {
        Calendar.current.date(
            bySettingHour: settings.reminderTime.hour, minute: settings.reminderTime.minute, second: 0, of: .now)
            ?? .now
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding {
            reminderTime
        } set: { date in
            let calendar = Calendar.current
            settings.reminderTime = TimeOfDay(
                hour: calendar.component(.hour, from: date), minute: calendar.component(.minute, from: date))
            saveReminder()
        }
    }

    private var reminderBinding: Binding<Bool> {
        Binding {
            settings.remindsDaily || isAskingPermission
        } set: { isOn in
            if isOn {
                isAskingPermission = true
            } else {
                settings.remindsDaily = false
                saveReminder()
            }
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func languageName(_ identifier: String) -> String {
        locale.localizedString(forIdentifier: identifier) ?? identifier
    }

    private func turnOnReminder() async {
        switch await ReadingReminder.requestPermission() {
        case .granted:
            settings.remindsDaily = true
            saveReminder()
        case .declined:
            break
        case .turnedOff:
            isNotificationsOffAlertShown = true
        }
        isAskingPermission = false
    }

    private func saveReminder() {
        try? modelContext.save()
        ReadingReminder.schedule(for: settings)
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<Settings, Value>) -> Binding<Value> {
        Binding {
            settings[keyPath: keyPath]
        } set: { value in
            settings[keyPath: keyPath] = value
            try? modelContext.save()
        }
    }
}
