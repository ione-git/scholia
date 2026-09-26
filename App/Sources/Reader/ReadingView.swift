import DesignSystem
import ReaderEngine
import SwiftData
import SwiftUI

struct ReadingView: View {
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings
    @State private var controller: ReaderController?
    @State private var cannotOpen = false
    @State private var isChromeShown = false

    var body: some View {
        ZStack {
            theme.page.ignoresSafeArea()
            if let controller {
                ReaderView(controller: controller)
                    .ignoresSafeArea()
            } else if cannotOpen {
                Text("This book can’t be opened.")
                    .textStyle(.body)
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .space7)
                    .accessibilityIdentifier("reader.failure")
            }
            page
        }
        .environment(\.colorScheme, theme.isDark ? .dark : .light)
        .statusBarHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task { await open() }
        .onChange(of: theme) { recolor() }
        .onChange(of: controller?.location) { _, location in save(location) }
        .onChange(of: controller?.page) { _, page in save(page) }
    }

    private var theme: ReaderTheme {
        settings.readerTheme.shown(in: colorScheme)
    }

    private var page: some View {
        VStack(spacing: 0) {
            Text(book.title)
                .textStyle(TextStyle.labelCaps.weighted(TextStyle.caption.weight))
                .foregroundStyle(.inkMuted)
                .lineLimit(1)
                .frame(height: .controlH)
                .padding(.horizontal, .space5 + .controlH)
                .padding(.top, .navTop)
                .accessibilityIdentifier("reader.runningHead")
            Spacer()
            if let page = controller?.page {
                Text("\(page.number) of \(page.count)")
                    .textStyle(.caption)
                    .foregroundStyle(.inkMuted)
                    .padding(.bottom, .space8 + .space1)
                    .accessibilityIdentifier("reader.pageCounter")
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            if isChromeShown || cannotOpen {
                GlassButton(.back, label: Text("Back"), size: .regular, isActive: false) { dismiss() }
                    .padding(.leading, .space4)
                    .padding(.top, .navTop)
                    .transition(.opacity)
                    .accessibilityIdentifier("reader.back")
            }
        }
        .ignoresSafeArea()
    }

    private func open() async {
        guard controller == nil, !cannotOpen else {
            return
        }
        do {
            let readerBook = try await ReaderBook.open(book.fileURL)
            let controller = ReaderController(
                book: readerBook,
                location: book.position.map { ReaderLocation(chapter: $0.chapter, offset: $0.offset) },
                style: .book,
                colors: theme.colors,
                highlightColor: theme.highlightColor,
                pageTurn: .slide,
                highlightTitle: String(localized: "Highlight")
            )
            let isChromeShown = $isChromeShown
            controller.onPageTap = { withAnimation { isChromeShown.wrappedValue.toggle() } }
            self.controller = controller
            book.openedAt = LaunchConfiguration.current.now ?? .now
            try? modelContext.save()
        } catch {
            cannotOpen = true
        }
    }

    private func recolor() {
        guard let controller else {
            return
        }
        controller.colors = theme.colors
        controller.highlightColor = theme.highlightColor
    }

    private func save(_ location: ReaderLocation?) {
        guard let location else {
            return
        }
        book.position = ReadingPosition(chapter: location.chapter, offset: location.offset)
        try? modelContext.save()
    }

    private func save(_ page: ReaderPage?) {
        guard let page else {
            return
        }
        book.progress = Double(page.number) / Double(page.count)
        try? modelContext.save()
    }
}
