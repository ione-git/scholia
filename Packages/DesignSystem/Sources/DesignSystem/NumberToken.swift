import CoreGraphics

public struct NumberToken: Identifiable, Sendable {
    public let name: String
    public let value: CGFloat

    public var id: String { name }
}
