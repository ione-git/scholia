import DesignSystem
import ReaderEngine
import SwiftData
import SwiftUI

struct ReaderChrome<MenuContent: View>: View {
    let book: Book
    let controller: ReaderController?
    let isShown: Bool
    let cannotOpen: Bool
    let menu: MenuContent
    let back: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            footer
        }
        .frame(maxWidth: .infinity)
    }

    private var showsControls: Bool {
        isShown && controller != nil
    }

    private var header: some View {
        ZStack {
            if showsControls {
                StackedTitle(
                    title: Text(book.title), subtitle: subtitle, titleIdentifier: "reader.title",
                    subtitleIdentifier: "reader.subtitle"
                )
                .transition(.opacity)
            } else {
                Text(book.title)
                    .textStyle(TextStyle.labelCaps.weighted(TextStyle.caption.weight))
                    .foregroundStyle(.inkMuted)
                    .lineLimit(1)
                    .accessibilityIdentifier("reader.runningHead")
                    .transition(.opacity)
            }
        }
        .frame(height: .controlH)
        .padding(.horizontal, .space5 + .controlH)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) {
            if showsControls || cannotOpen {
                GlassButton(.back, label: Text("Back"), size: .regular, isActive: false, action: back)
                    .padding(.leading, .space4)
                    .transition(.opacity)
                    .accessibilityIdentifier("reader.back")
            }
        }
        .overlay(alignment: .trailing) {
            if showsControls {
                bookmarkButton
                    .padding(.trailing, .space4)
                    .transition(.opacity)
            }
        }
        .padding(.top, .navTop)
        .background { scrollBackdrop }
    }

    private var footer: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let page = controller?.page {
                    Text("\(page.number) of \(page.count)")
                        .textStyle(.caption)
                        .foregroundStyle(.inkMuted)
                        .accessibilityIdentifier("reader.pageCounter")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, .space8 + .space1)
            if showsControls {
                menu
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, .space5)
                    .padding(.bottom, .space6)
                    .transition(.opacity)
                    .accessibilityIdentifier("reader.menu")
            }
        }
        .frame(height: GlassButton.Size.reader.diameter + .space6, alignment: .bottom)
        .background { scrollBackdrop }
    }

    @ViewBuilder
    private var scrollBackdrop: some View {
        if let controller, controller.appearance.pageTurn == .scroll {
            Color(uiColor: controller.appearance.colors.page)
                .allowsHitTesting(false)
        }
    }

    private var bookmarkButton: some View {
        let span = controller?.pageSpan
        let isBookmarked = span.map { !book.bookmarks(in: $0).isEmpty } ?? false
        return GlassButton(
            isBookmarked ? .bookmarkFilled : .bookmark,
            label: isBookmarked ? Text("Bookmarked. Remove bookmark") : Text("Bookmark this page"), size: .regular,
            isActive: false
        ) {
            if let span {
                book.toggleBookmark(in: span, context: modelContext)
            }
        }
        .disabled(span == nil)
        .accessibilityAddTraits(isBookmarked ? .isSelected : [])
        .accessibilityIdentifier("reader.bookmark")
    }

    private var subtitle: Text? {
        let chapter = controller?.location.flatMap { controller?.book.chapter(containing: $0) }?.title
        switch (book.author, chapter) {
        case (let author?, let chapter?): return Text("\(author) · \(chapter)")
        case (let author?, nil): return Text(author)
        case (nil, let chapter?): return Text(chapter)
        case (nil, nil): return nil
        }
    }

}
