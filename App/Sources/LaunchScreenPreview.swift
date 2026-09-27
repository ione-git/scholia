#if DEBUG
    import SwiftUI

    struct LaunchScreenPreview: View {
        @Environment(\.colorScheme) private var colorScheme

        private let entry = Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen") as? [String: Any]

        var body: some View {
            if let colorName = entry?["UIColorName"] as? String, UIColor(named: colorName) != nil,
                let imageName = entry?["UIImageName"] as? String,
                let image = UIImage(named: imageName, in: nil, compatibleWith: traits),
                let displayP3 = CGColorSpace(name: CGColorSpace.displayP3),
                let glyph = image.cgImage?.copy(colorSpace: displayP3)
            {
                Color(colorName)
                    .overlay {
                        Image(glyph, scale: image.scale, label: Text("Scholia"))
                            .accessibilityIdentifier("launchScreen.glyph")
                    }
                    .ignoresSafeArea()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }

        private var traits: UITraitCollection {
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        }
    }
#endif
