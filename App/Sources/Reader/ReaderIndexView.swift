import DesignSystem
import ReaderEngine
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
    let controller: ReaderController

    @Environment(\.dismiss) private var dismiss
    @State private var tab: ReaderIndexTab

    init(book: Book, controller: ReaderController, tab: ReaderIndexTab) {
        self.book = book
        self.controller = controller
        _tab = State(initialValue: tab)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: .space4) {
                header
                SegmentedControl(
                    selection: $tab, size: .regular,
                    segments: ReaderIndexTab.allCases.map {
                        .init(
                            $0, title: Text($0.title), count: count(of: $0),
                            identifier: "readerIndex.tab.\($0.rawValue)")
                    })
            }
            .padding(.horizontal, .space5)
            switch tab {
            case .contents:
                ReaderContentsList(controller: controller)
            case .highlights, .bookmarks:
                Spacer(minLength: 0)
            }
        }
        .background(.surface)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { dismiss() }
    }

    private func count(of tab: ReaderIndexTab) -> Int? {
        switch tab {
        case .contents: nil
        case .highlights: book.highlights.count
        case .bookmarks: book.bookmarks.count
        }
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
