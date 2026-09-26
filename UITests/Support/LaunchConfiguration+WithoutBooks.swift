extension LaunchConfiguration {
    static let withoutBooks = LaunchConfiguration(
        resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
        now: nil,
        notificationPermission: nil)
}
