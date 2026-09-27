#if DEBUG
    import SwiftUI

    struct PrivacyDiagnostics: View {
        private static let summary =
            PrivacyManifest.bundled.map { (label: $0.accessedAPIs, value: $0.declarations) }
            ?? (label: "no manifest", value: "no manifest")

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.privacyManifest")
                .accessibilityLabel(Text(verbatim: Self.summary.label))
                .accessibilityValue(Text(verbatim: Self.summary.value))
        }
    }

    private struct PrivacyManifest: Decodable {
        struct AccessedAPI: Decodable {
            let category: String
            let reasons: [String]

            enum CodingKeys: String, CodingKey {
                case category = "NSPrivacyAccessedAPIType"
                case reasons = "NSPrivacyAccessedAPITypeReasons"
            }
        }

        struct CollectedDataType: Decodable {}

        let tracking: Bool
        let trackingDomains: [String]
        let collectedDataTypes: [CollectedDataType]
        let accessedAPITypes: [AccessedAPI]

        enum CodingKeys: String, CodingKey {
            case tracking = "NSPrivacyTracking"
            case trackingDomains = "NSPrivacyTrackingDomains"
            case collectedDataTypes = "NSPrivacyCollectedDataTypes"
            case accessedAPITypes = "NSPrivacyAccessedAPITypes"
        }

        static var bundled: PrivacyManifest? {
            guard let url = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"),
                let data = try? Data(contentsOf: url)
            else { return nil }
            return try? PropertyListDecoder().decode(PrivacyManifest.self, from: data)
        }

        var accessedAPIs: String {
            accessedAPITypes.map { "\($0.category) · \($0.reasons.joined(separator: ", "))" }.sorted()
                .joined(separator: "\n")
        }

        var declarations: String {
            [
                "tracking \(tracking)",
                "\(trackingDomains.count) tracking domains",
                "\(collectedDataTypes.count) collected data types",
            ]
            .joined(separator: " · ")
        }
    }
#endif
