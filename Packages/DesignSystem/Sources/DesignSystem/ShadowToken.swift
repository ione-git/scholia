import SwiftUI
import UIKit

public struct ShadowToken: Identifiable, Sendable {
    public struct Layer: Sendable {
        public let x: CGFloat
        public let y: CGFloat
        public let blur: CGFloat
        public let spread: CGFloat
        public let color: Color
        public let isInset: Bool

        static func drop(x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat, color: UIColor) -> Layer {
            Layer(x: x, y: y, blur: blur, spread: spread, color: Color(uiColor: color), isInset: false)
        }

        static func inset(x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat, color: UIColor) -> Layer {
            Layer(x: x, y: y, blur: blur, spread: spread, color: Color(uiColor: color), isInset: true)
        }
    }

    public let name: String
    public let layers: [Layer]

    public var id: String { name }
}

extension View {
    public func shadow(_ token: ShadowToken, in shape: some InsettableShape) -> some View {
        background {
            ForEach(token.layers.indices, id: \.self) { index in
                let layer = token.layers[index]
                if !layer.isInset {
                    shape.inset(by: -layer.spread)
                        .fill(layer.color)
                        .blur(radius: layer.blur / 2)
                        .offset(x: layer.x, y: layer.y)
                }
            }
        }
        .overlay {
            ForEach(token.layers.indices, id: \.self) { index in
                let layer = token.layers[index]
                if layer.isInset {
                    shape.subtracting(shape.inset(by: layer.spread).offset(x: layer.x, y: layer.y))
                        .fill(layer.color)
                        .blur(radius: layer.blur / 2)
                        .clipShape(shape)
                }
            }
        }
    }
}
