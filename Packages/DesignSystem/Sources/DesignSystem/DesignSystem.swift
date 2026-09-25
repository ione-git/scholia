import CoreText
import Foundation

public enum DesignSystem {
    static let serifFontName = "Literata-Regular"
    public static let serifFamilyName = "Literata"
    public static let serifFontURL = fontURL("Literata-VariableFont_opsz,wght")
    public static let serifItalicFontURL = fontURL("Literata-Italic-VariableFont_opsz,wght")

    public static func registerFonts() {
        for url in Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func fontURL(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")!
    }
}
