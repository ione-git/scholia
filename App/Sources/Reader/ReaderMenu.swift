import DesignSystem
import SwiftUI

struct ReaderMenu: View {
    @Binding var indexTab: ReaderIndexTab?
    @Binding var isSettingsShown: Bool

    var body: some View {
        Menu {
            item(.contents, icon: .contents)
            item(.highlights, icon: .highlighter)
            item(.bookmarks, icon: .bookmark)
            Divider()
            Button {
                isSettingsShown = true
            } label: {
                Label("Themes & Settings", systemImage: "textformat")
            }
            .accessibilityIdentifier("readerMenu.settings")
        } label: {
            GlassMenuLabel(.more, label: Text("Menu"), size: .reader)
        }
        .accessibilityLabel(Text("Menu"))
        .accessibilityIdentifier("reader.menu")
    }

    private func item(_ tab: ReaderIndexTab, icon: Icon) -> some View {
        Button {
            indexTab = tab
        } label: {
            Label {
                Text(tab.title)
            } icon: {
                icon.menuImage
            }
        }
        .accessibilityIdentifier("readerMenu.\(tab.rawValue)")
    }
}
