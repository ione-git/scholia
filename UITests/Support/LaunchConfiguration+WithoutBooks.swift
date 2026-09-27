extension LaunchConfiguration {
    static let withoutBooks = LaunchConfiguration(
        resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
        now: nil,
        notificationPermission: nil)
}
