import DesignSystem
import ReaderEngine
import SwiftUI

struct ReaderBookmarksList: View {
    let controller: ReaderController
    private let bookmarks: [Bookmark]
    private let lineLocale: Locale

    @Environment(\.dismiss) private var dismiss

    init(book: Book, controller: ReaderController) {
        self.controller = controller
        bookmarks = book.bookmarksInReadingOrder
        lineLocale = Locale(identifier: book.language)
    }

    var body: some View {
        ScrollView {
            if !bookmarks.isEmpty {
                LazyGroupedList(bookmarks.indices) { index in
                    row(at: index)
                }
                .shadow(.card, in: RoundedRectangle(cornerRadius: .radiusLg))
                .padding(.horizontal, .space5)
                .padding(.top, .space4)
                .padding(.bottom, .space10)
            }
        }
    }

    private func row(at index: Int) -> some View {
        let bookmark = bookmarks[index]
        let location = bookmark.position.location
        let page = controller.page(of: location)
        let title = title(page: page, chapter: controller.book.chapter(containing: location))
        return Button {
            dismiss()
            controller.go(to: location)
        } label: {
            BookmarkRow(title: title, line: line(of: bookmark), lineLocale: lineLocale)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(bookmark.text ?? "")
        .accessibilityIdentifier("readerIndex.bookmark.\(key(at: index, page: page))")
    }

    private func key(at index: Int, page: Int?) -> String {
        if let page, index == 0 || controller.page(of: bookmarks[index - 1].position.location) != page {
            return "\(page)"
        }
        let position = bookmarks[index].position
        return "\(position.chapter)-\(position.offset)"
    }

    private func line(of bookmark: Bookmark) -> Text? {
        guard let text = bookmark.text, !text.isEmpty else {
            return nil
        }
        return Text(text)
    }

    private func title(page: Int?, chapter: ReaderChapter?) -> Text {
        let page = page.map { page in
            BookmarkRow.page(
                Text(
                    LocalizedStringResource(
                        "readerBookmarks.page", defaultValue: "Page \(page)",
                        comment: "Bookmarks row: the page the bookmark is on")))
        }
        let chapter = chapter.map { Text($0.title) }
        switch (page, chapter) {
        case (let page?, let chapter?):
            return Text(
                "\(page) · \(chapter)",
                comment: "Two parts of one line joined by a middle dot, e.g. a bookmark's page, then its chapter")
        case (let page?, nil):
            return page
        case (nil, let chapter?):
            return chapter
        case (nil, nil):
            return BookmarkRow.page(
                Text(
                    LocalizedStringResource(
                        "readerBookmarks.bookmark", defaultValue: "Bookmark",
                        comment: "Bookmarks row when neither the page nor the chapter of the bookmark is known")))
        }
    }
}
