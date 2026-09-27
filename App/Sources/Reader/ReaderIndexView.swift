import DesignSystem
import SwiftUI

enum ReaderIndexTab: String, CaseIterable, Identifiable {
    case contents
    case highlights
    case bookmarks

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .contents: "Contents"
        case .highlights: "Highlights"
        case .bookmarks: "Bookmarks"
        }
    }
}

struct ReaderIndexView: View {
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @State private var tab: ReaderIndexTab

    init(book: Book, tab: ReaderIndexTab) {
        self.book = book
        _tab = State(initialValue: tab)
    }

    var body: some View {
        VStack(spacing: .space4) {
            header
            SegmentedControl(
                selection: $tab, size: .regular,
                segments: ReaderIndexTab.allCases.map {
                    .init($0, title: Text($0.title), count: nil, identifier: "readerIndex.tab.\($0.rawValue)")
                })
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .space5)
        .background(.surface)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { dismiss() }
    }

    private var header: some View {
        StackedTitle(
            title: Text(book.title), subtitle: book.author.map { Text($0) }, titleIdentifier: "readerIndex.title",
            subtitleIdentifier: "readerIndex.subtitle"
        )
        .padding(.horizontal, .space4 + .controlH)
        .frame(maxWidth: .infinity, minHeight: .controlH)
        .overlay(alignment: .trailing) {
            Button("Done") { dismiss() }
                .buttonStyle(.sheetDone)
                .accessibilityIdentifier("readerIndex.done")
        }
    }
}
