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
        let url = try XCTUnwrap(Bundle(for: UITestCase.self).url(forResource: "tokens", withExtension: "json"))
        return try JSONDecoder().decode(DesignTokens.self, from: Data(contentsOf: url))
    }
}
