import Foundation

enum Fixture: String {
    case german
    case frenchNoCover = "french-no-cover"
    case arabic
    case minimalMetadata = "minimal-metadata"
    case corrupted
    case drm

    var url: URL? {
        Bundle.main.url(forResource: rawValue, withExtension: "epub", subdirectory: "Fixtures")
    }
}

enum TranslationMock: String {
    case immediate = "mock"
    case held
}

enum NotificationPermission: String {
    case declined
    case denied
}

struct LaunchConfiguration {
    var resetsState: Bool
    var fixtures: [Fixture]
    var opened: [Fixture]
    var inProgress: [Fixture]
    var highlighted: [Fixture]
    var translation: TranslationMock?
    var now: Date?
    var notificationPermission: NotificationPermission?

    static let current = LaunchConfiguration(environment: ProcessInfo.processInfo.environment)
}

extension LaunchConfiguration {
    private enum Key {
        static let resetsState = "SCHOLIA_RESET_STATE"
        static let fixtures = "SCHOLIA_FIXTURES"
        static let opened = "SCHOLIA_OPENED"
        static let inProgress = "SCHOLIA_IN_PROGRESS"
        static let highlighted = "SCHOLIA_HIGHLIGHTED"
        static let translation = "SCHOLIA_TRANSLATION"
        static let now = "SCHOLIA_NOW"
        static let notificationPermission = "SCHOLIA_NOTIFICATIONS"
    }

    init(environment: [String: String]) {
        #if DEBUG
            self.init(
                resetsState: environment[Key.resetsState] == "1",
                fixtures: Self.fixtures(environment[Key.fixtures]),
                opened: Self.fixtures(environment[Key.opened]),
                inProgress: Self.fixtures(environment[Key.inProgress]),
                highlighted: Self.fixtures(environment[Key.highlighted]),
                translation: environment[Key.translation].flatMap(TranslationMock.init),
                now: environment[Key.now].flatMap { try? Date($0, strategy: .iso8601) },
                notificationPermission: environment[Key.notificationPermission].flatMap(NotificationPermission.init)
            )
        #else
            self.init(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: nil,
                now: nil,
                notificationPermission: nil)
        #endif
    }

    private static func fixtures(_ value: String?) -> [Fixture] {
        value?.split(separator: ",").compactMap { Fixture(rawValue: String($0)) } ?? []
    }

    var environment: [String: String] {
        var environment: [String: String] = [:]
        if resetsState {
            environment[Key.resetsState] = "1"
        }
        if !fixtures.isEmpty {
            environment[Key.fixtures] = fixtures.map(\.rawValue).joined(separator: ",")
        }
        if !opened.isEmpty {
            environment[Key.opened] = opened.map(\.rawValue).joined(separator: ",")
        }
        if !inProgress.isEmpty {
            environment[Key.inProgress] = inProgress.map(\.rawValue).joined(separator: ",")
        }
        if !highlighted.isEmpty {
            environment[Key.highlighted] = highlighted.map(\.rawValue).joined(separator: ",")
        }
        if let translation {
            environment[Key.translation] = translation.rawValue
        }
        if let now {
            environment[Key.now] = now.formatted(.iso8601)
        }
        if let notificationPermission {
            environment[Key.notificationPermission] = notificationPermission.rawValue
        }
        return environment
    }

    var summary: String {
        environment.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
    }
}

enum TestAnimations {
    static let environmentKey = "SCHOLIA_ANIMATIONS"
    static let off = "off"

    static let areOff: Bool = {
        #if DEBUG
            ProcessInfo.processInfo.environment[environmentKey] == off
        #else
            false
        #endif
    }()
}
