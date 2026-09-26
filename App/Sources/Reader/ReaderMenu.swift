import DesignSystem
import SwiftUI

struct ReaderMenu: View {
    @Binding var isShown: Bool
    @Binding var indexTab: ReaderIndexTab?
    @Binding var isSettingsShown: Bool

    var body: some View {
        GlassMenu(size: .reader) {
            item(.contents, icon: .contents)
            item(.highlights, icon: .highlighter)
            item(.bookmarks, icon: .bookmark)
            GlassMenuDivider()
            GlassMenuItem(Text("Themes & Settings"), sample: Text(verbatim: "Aa")) {
                isShown = false
                isSettingsShown = true
            }
            .accessibilityIdentifier("readerMenu.settings")
        }
    }

    private func item(_ tab: ReaderIndexTab, icon: Icon) -> some View {
        GlassMenuItem(Text(tab.title), icon: icon) {
            isShown = false
            indexTab = tab
        }
        .accessibilityIdentifier("readerMenu.\(tab.rawValue)")
    }
}
