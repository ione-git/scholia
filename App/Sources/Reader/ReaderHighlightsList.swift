import DesignSystem
import ReaderEngine
import SwiftUI

struct ReaderHighlightsList: View {
    let controller: ReaderController
    let locale: Locale
    let quoteDirection: LayoutDirection

    @State private var highlights: [Highlight]

    init(book: Book, controller: ReaderController) {
        self.controller = controller
        locale = Locale(identifier: book.language)
        quoteDirection = locale.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
        _highlights = State(initialValue: book.highlights.sorted(by: Highlight.isInBookOrder))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .space3) {
                ForEach(highlights) { highlight in
                    ReaderHighlightRow(
                        highlight: highlight, controller: controller, locale: locale, quoteDirection: quoteDirection)
                }
            }
            .padding(.horizontal, .space5)
            .padding(.top, .space4)
            .padding(.bottom, .space10)
        }
    }
}

private struct ReaderHighlightRow: View {
    let highlight: Highlight
    let controller: ReaderController
    let locale: Locale
    let quoteDirection: LayoutDirection

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let start = highlight.range.start
        let chapter = controller.book.chapter(containing: start)?.title
        let page = controller.page(of: start)
        Button {
            dismiss()
            controller.go(to: start)
        } label: {
            HighlightCard(
                quote: Text(verbatim: highlight.text, spokenIn: locale), quoteDirection: quoteDirection,
                color: highlight.color.solid.color,
                meta: meta(chapter: chapter, page: page))
        }
        .buttonStyle(.plain)
        .accessibilityValue(value(chapter: chapter, page: page))
        .accessibilityIdentifier("readerIndex.highlight.\(highlight.key)")
    }

    private func meta(chapter: String?, page: Int?) -> Text? {
        switch (chapter, page) {
        case (let chapter?, let page?):
            Text(
                LocalizedStringResource(
                    "readerHighlights.meta.chapterPage", defaultValue: "\(chapter) · Page \(page)",
                    comment: "Highlights list row, under the quote: chapter title and page of the highlight"))
        case (nil, let page?):
            Text(
                LocalizedStringResource(
                    "readerHighlights.meta.page", defaultValue: "Page \(page)",
                    comment: "Highlights list row, under the quote: page of a highlight outside any chapter"))
        case (let chapter?, nil):
            Text(verbatim: chapter)
        case (nil, nil):
            nil
        }
    }

    private func value(chapter: String?, page: Int?) -> String {
        let color = String(localized: highlight.color.name)
        return switch (chapter, page) {
        case (let chapter?, let page?):
            String(
                localized: "readerHighlights.value.colorChapterPage",
                defaultValue: "\(color), \(chapter), Page \(page)",
                comment: "Highlights list row, VoiceOver value: colour, chapter title and page of the highlight")
        case (let chapter?, nil):
            String(
                localized: "readerHighlights.value.colorChapter", defaultValue: "\(color), \(chapter)",
                comment: "Highlights list row, VoiceOver value: colour and chapter title of the highlight")
        case (nil, let page?):
            String(
                localized: "readerHighlights.value.colorPage", defaultValue: "\(color), Page \(page)",
                comment: "Highlights list row, VoiceOver value: colour and page of a highlight outside any chapter")
        case (nil, nil):
            color
        }
    }
}
