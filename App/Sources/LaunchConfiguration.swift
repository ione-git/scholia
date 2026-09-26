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

struct LaunchConfiguration {
    var resetsState: Bool
    var fixtures: [Fixture]
    var opened: [Fixture]
    var mocksTranslation: Bool
    var now: Date?

    static let current = LaunchConfiguration(environment: ProcessInfo.processInfo.environment)
}

extension LaunchConfiguration {
    private enum Key {
        static let resetsState = "SCHOLIA_RESET_STATE"
        static let fixtures = "SCHOLIA_FIXTURES"
        static let opened = "SCHOLIA_OPENED"
        static let translation = "SCHOLIA_TRANSLATION"
        static let now = "SCHOLIA_NOW"
    }

    init(environment: [String: String]) {
        #if DEBUG
            self.init(
                resetsState: environment[Key.resetsState] == "1",
                fixtures: Self.fixtures(environment[Key.fixtures]),
                opened: Self.fixtures(environment[Key.opened]),
                mocksTranslation: environment[Key.translation] == "mock",
                now: environment[Key.now].flatMap { try? Date($0, strategy: .iso8601) }
            )
        #else
            self.init(resetsState: false, fixtures: [], opened: [], mocksTranslation: false, now: nil)
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
        if mocksTranslation {
            environment[Key.translation] = "mock"
        }
        if let now {
            environment[Key.now] = now.formatted(.iso8601)
        }
        return environment
    }

    var summary: String {
        environment.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
    }
}
