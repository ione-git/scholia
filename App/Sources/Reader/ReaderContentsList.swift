import DesignSystem
import ReaderEngine
import SwiftUI

struct ReaderContentsList: View {
    let controller: ReaderController

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let chapters = controller.book.tableOfContents
        let current = controller.location.flatMap { controller.book.indexOfChapter(containing: $0) }
        ScrollViewReader { proxy in
            ScrollView {
                LazyGroupedList(chapters.indices) { index in
                    row(chapters[index], at: index, isCurrent: index == current)
                }
                .shadow(.card, in: RoundedRectangle(cornerRadius: .radiusLg))
                .padding(.horizontal, .space5)
                .padding(.top, .space4)
                .padding(.bottom, .space10)
            }
            .onAppear {
                if let current {
                    proxy.scrollTo(current, anchor: .center)
                }
            }
        }
    }

    private func row(_ chapter: ReaderChapter, at index: Int, isCurrent: Bool) -> some View {
        let page = controller.startPage(ofChapterAt: index)
        return Button {
            dismiss()
            controller.go(toChapterAt: index)
        } label: {
            ChapterRow(Text(chapter.title), page: page, isCurrent: isCurrent)
        }
        .buttonStyle(.plain)
        .accessibilityValue(
            page.map { String(localized: "Page \($0)", comment: "Contents row: start page of the chapter") } ?? ""
        )
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityIdentifier("readerIndex.chapter.\(chapter.title)")
    }
}
