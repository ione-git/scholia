import DesignSystem
import ReaderEngine
import SwiftUI

struct ReaderContentsList: View {
    let controller: ReaderController
    let onJump: (ReaderChapter) -> Void

    var body: some View {
        let current = controller.location.flatMap { controller.book.chapter(containing: $0) }?.index
        ScrollViewReader { proxy in
            LazyGroupedList(controller.book.tableOfContents, id: \.index) { chapter in
                row(chapter, isCurrent: chapter.index == current)
            }
            .shadow(.card, in: RoundedRectangle(cornerRadius: .radiusLg))
            .onAppear {
                if let current {
                    proxy.scrollTo(current, anchor: .center)
                }
            }
        }
    }

    private func row(_ chapter: ReaderChapter, isCurrent: Bool) -> some View {
        let page = controller.startPage(of: chapter)
        return Button {
            onJump(chapter)
        } label: {
            ChapterRow(title: chapter.title, page: page, isCurrent: isCurrent)
        }
        .buttonStyle(.plain)
        .accessibilityValue(
            page.map { String(localized: "Page \($0)", comment: "Start page of a chapter in Contents") } ?? ""
        )
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityIdentifier("readerIndex.chapter.\(chapter.index)")
    }
}
