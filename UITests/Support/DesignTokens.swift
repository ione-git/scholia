import XCTest

struct DesignTokens: Decodable {
    struct Token: Decodable {
        let name: String
    }

    struct Category: Decodable {
        let tokens: [Token]
    }

    struct TypeGroup: Decodable {
        let family: String
        let styles: [Token]
    }

    struct Typography: Decodable {
        let groups: [TypeGroup]
    }

    let color: Category
    let type: Typography
    let spacing: Category
    let radius: Category
    let shadow: Category
    let effects: Category

    static func load() throws -> DesignTokens {
        try JSONDecoder().decode(DesignTokens.self, from: data())
    }

    static func data() throws -> Data {
        let url = try XCTUnwrap(Bundle(for: UITestCase.self).url(forResource: "tokens", withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

struct TokenValues {
    private let json: [String: Any]

    static func load() throws -> TokenValues {
        TokenValues(json: try XCTUnwrap(JSONSerialization.jsonObject(with: DesignTokens.data()) as? [String: Any]))
    }

    func color(_ name: String, dark: Bool) throws -> RGB {
        let tokens = try XCTUnwrap((json["color"] as? [String: Any])?["tokens"] as? [[String: Any]])
        let value = try XCTUnwrap(tokens.first { $0["name"] as? String == name }?["value"], name)
        let hex = (value as? [String: String])?[dark ? "dark" : "light"] ?? value as? String
        return try RGB(hex: XCTUnwrap(hex, name))
    }

    func lineHeight(_ style: String) throws -> CGFloat {
        let groups = try XCTUnwrap((json["type"] as? [String: Any])?["groups"] as? [[String: Any]])
        let styles = groups.flatMap { $0["styles"] as? [[String: Any]] ?? [] }
        let value = try XCTUnwrap(styles.first { $0["name"] as? String == style }?["lineHeight"] as? String, style)
        return try CGFloat(XCTUnwrap(Double(value.replacingOccurrences(of: "px", with: "")), style))
    }
}
