import CoreText
import Foundation

public enum DesignSystem {
    static let serifFontName = "Literata-Regular"

    public static func registerFonts() {
        for url in Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
