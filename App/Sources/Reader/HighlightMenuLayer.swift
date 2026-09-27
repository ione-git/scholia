import DesignSystem
import OSLog
import ReaderEngine
import SwiftData
import SwiftUI

struct HighlightMenuLayer: View {
    let book: Book
    let controller: ReaderController

    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings

    var body: some View {
        if let tapped = controller.tappedHighlight,
            let highlight = book.highlights.first(where: { $0.key == tapped.id })
        {
            TranslationBubblePlacement(anchor: tapped.rect, topLimit: .navTop + .controlH, gap: .highlightMenu) {
                HighlightColorMenu {
                    ForEach(HighlightColor.allCases, id: \.self) { color in
                        HighlightSwatch(
                            color: color.solid.color, label: Text(color.name), isSelected: highlight.color == color
                        ) {
                            recolor(highlight, to: color)
                        }
                        .accessibilityIdentifier("reader.highlightMenu.\(color.rawValue)")
                    }
                } delete: {
                    HighlightDeleteButton(
                        label: Text("Remove highlight", comment: "Button in the highlight colour menu that deletes it")
                    ) {
                        delete(highlight)
                    }
                    .accessibilityIdentifier("reader.highlightMenu.delete")
                }
                .accessibilityLabel(Text("Highlight color", comment: "Menu of colours for a tapped highlight"))
                .accessibilityIdentifier("reader.highlightMenu")
                .accessibilityAction(.escape) { controller.clearTappedHighlight() }
            }
            .ignoresSafeArea()
        }
    }

    private func recolor(_ highlight: Highlight, to color: HighlightColor) {
        highlight.color = color
        settings.highlightColor = color
        do {
            try modelContext.save()
        } catch {
            logger.error("Recolouring a highlight failed: \(error.localizedDescription, privacy: .public)")
        }
        controller.clearTappedHighlight()
    }

    private func delete(_ highlight: Highlight) {
        book.highlights.removeAll { $0.persistentModelID == highlight.persistentModelID }
        modelContext.delete(highlight)
        do {
            try modelContext.save()
        } catch {
            logger.error("Deleting a highlight failed: \(error.localizedDescription, privacy: .public)")
        }
        controller.clearTappedHighlight()
    }
}

private let logger = Logger(subsystem: "com.ione.scholia", category: "reader")
