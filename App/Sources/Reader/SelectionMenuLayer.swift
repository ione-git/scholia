import DesignSystem
import ReaderEngine
import SwiftUI

struct SelectionMenuLayer: View {
    let controller: ReaderController

    var body: some View {
        if let selection = controller.selection {
            TranslationBubblePlacement(anchor: selection.rect, topLimit: .navTop + .controlH, gap: .selectionMenu) {
                SelectionMenu {
                    SelectionMenuItem(
                        Text("Highlight", comment: "Selection menu item that highlights the selected text"),
                        isPrimary: true
                    ) {
                        controller.highlightSelection()
                    }
                    .accessibilityIdentifier("reader.selectionMenu.highlight")
                    SelectionMenuItem(
                        Text("Translate", comment: "Selection menu item that translates the selected text"),
                        isPrimary: false
                    ) {
                        controller.translateSelection()
                    }
                    .accessibilityIdentifier("reader.selectionMenu.translate")
                    SelectionMenuItem(
                        Text("Copy", comment: "Selection menu item that copies the selected text"),
                        isPrimary: false
                    ) {
                        controller.copySelection()
                    }
                    .accessibilityIdentifier("reader.selectionMenu.copy")
                }
                .accessibilityIdentifier("reader.selectionMenu")
                .accessibilityAction(.escape) { controller.clearSelection() }
            }
            .ignoresSafeArea()
        }
    }
}
