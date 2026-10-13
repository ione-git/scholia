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
                .padding(.bottom, .space10)
            }
            .clipShape(.rect(cornerRadius: .radiusLg))
            .padding(.horizontal, .space5)
            .padding(.top, .space4)
            .onAppear {
                if let current, current > chapters[current].depth {
                    proxy.scrollTo(current, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ chapter: ReaderChapter, at index: Int, isCurrent: Bool) -> some View {
        if chapter.location == nil {
            ChapterRow(Text(chapter.title), page: nil, isCurrent: false)
                .padding(.leading, CGFloat(chapter.depth) * .space4)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("readerIndex.section.\(chapter.title)")
        } else {
            let page = controller.startPage(ofChapterAt: index)
            Button {
                dismiss()
                controller.go(toChapterAt: index)
            } label: {
                ChapterRow(Text(chapter.title), page: page, isCurrent: isCurrent)
                    .padding(.leading, CGFloat(chapter.depth) * .space4)
            }
            .buttonStyle(.plain)
            .accessibilityValue(
                page.map { String(localized: "Page \($0)", comment: "Contents row: start page of the chapter") } ?? ""
            )
            .accessibilityAddTraits(isCurrent ? .isSelected : [])
            .accessibilityIdentifier("readerIndex.chapter.\(chapter.title)")
        }
    }
}
