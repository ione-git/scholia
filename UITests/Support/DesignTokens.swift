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
        try RGB(hex: colorValue(name, dark: dark))
    }

    func color(_ name: String, dark: Bool, over background: RGB) throws -> RGB {
        let value = try colorValue(name, dark: dark)
        let rgba = try XCTUnwrap(value.wholeMatch(of: /rgba\((\d+),(\d+),(\d+),([\d.]+)\)/), value).output
        let alpha = try XCTUnwrap(Double(rgba.4), value)
        let channels = try [rgba.1, rgba.2, rgba.3].map { try XCTUnwrap(Double($0), value) }
        let blend = { (top: Double, bottom: Int) in Int((top * alpha + Double(bottom) * (1 - alpha)).rounded()) }
        return RGB(
            red: blend(channels[0], background.red), green: blend(channels[1], background.green),
            blue: blend(channels[2], background.blue))
    }

    private func colorValue(_ name: String, dark: Bool) throws -> String {
        let tokens = try XCTUnwrap((json["color"] as? [String: Any])?["tokens"] as? [[String: Any]])
        let value = try XCTUnwrap(tokens.first { $0["name"] as? String == name }?["value"], name)
        return try XCTUnwrap((value as? [String: String])?[dark ? "dark" : "light"] ?? value as? String, name)
    }

    func lineHeight(_ style: String) throws -> CGFloat {
        let groups = try XCTUnwrap((json["type"] as? [String: Any])?["groups"] as? [[String: Any]])
        let styles = groups.flatMap { $0["styles"] as? [[String: Any]] ?? [] }
        let value = try XCTUnwrap(styles.first { $0["name"] as? String == style }?["lineHeight"] as? String, style)
        return try CGFloat(XCTUnwrap(Double(value.replacingOccurrences(of: "px", with: "")), style))
    }
}
