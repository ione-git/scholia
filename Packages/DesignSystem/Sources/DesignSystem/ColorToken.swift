import SwiftUI
import UIKit

public struct ColorToken: Identifiable, Sendable {
    public let name: String
    public let light: Color
    public let dark: Color
    public let color: Color

    public var id: String { name }

    init(name: String, light: UIColor, dark: UIColor) {
        self.name = name
        self.light = Color(uiColor: light)
        self.dark = Color(uiColor: dark)
        color = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

extension UIColor {
    convenience init(rgb: UInt32, opacity: CGFloat) {
        self.init(
            red: CGFloat(rgb >> 16 & 0xff) / 255,
            green: CGFloat(rgb >> 8 & 0xff) / 255,
            blue: CGFloat(rgb & 0xff) / 255,
            alpha: opacity
        )
    }
}
