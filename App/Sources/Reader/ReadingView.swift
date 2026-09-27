import DesignSystem
import OSLog
import ReaderEngine
import SwiftData
import SwiftUI

struct ReadingView: View {
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled
    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings
    @State private var controller: ReaderController?
    @State private var cannotOpen = false
    @State private var isChromeShown = false
    @State private var isMenuShown = false
    @State private var indexTab: ReaderIndexTab?
    @State private var isSettingsShown = false

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
            ReaderChrome(
                book: book, controller: controller, isShown: isChromeShown || isVoiceOverEnabled,
                cannotOpen: cannotOpen, isMenuShown: $isMenuShown
            ) {
                dismiss()
            }
            .glassMenu(isPresented: $isMenuShown, alignment: .bottomTrailing) {
                ReaderMenu(isShown: $isMenuShown, indexTab: $indexTab, isSettingsShown: $isSettingsShown)
                    .padding(.bottom, ReaderChrome.menuBottomInset)
                    .padding(.trailing, .space5)
            }
            .ignoresSafeArea()
            if let controller {
                HighlightPainter(book: book, controller: controller, theme: theme)
                SelectionMenuLayer(controller: controller)
                HighlightMenuLayer(book: book, controller: controller)
            }
            if let controller, let word = controller.word {
                TranslationBubblePlacement(anchor: word.rect, topLimit: .navTop + .controlH, gap: .bubble) {
                    WordBubble(word: word, language: book.language)
                        .accessibilityAction(.escape) { controller.clearWord() }
                }
                .id(word.range)
                .ignoresSafeArea()
            }
        }
        #if DEBUG
            .background {
                PaintedDiagnostics(identifier: "debug.paintedWordTints", count: controller?.paintedWordTints ?? 0)
            }
            .background {
                PaintedDiagnostics(identifier: "debug.paintedHighlights", count: controller?.paintedHighlights ?? 0)
            }
            .background {
                PaintedDiagnostics(
                    identifier: "debug.paintedHighlightRings", count: controller?.paintedHighlightRings ?? 0)
            }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("reader.page")
        .environment(\.colorScheme, shownColorScheme)
        .statusBarHidden()
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $indexTab) { tab in
            ReaderIndexView(book: book, tab: tab)
                .preferredColorScheme(shownColorScheme)
        }
        .sheet(isPresented: $isSettingsShown) {
            ReaderSettingsSheet()
                .preferredColorScheme(shownColorScheme)
        }
        .task { await open() }
        .onChange(of: theme) { recolor() }
        .onChange(of: settings.highlightColor) { recolor() }
        .onChange(of: controller?.location) { _, location in save(location) }
        .onChange(of: controller?.page) { _, page in save(page) }
    }

    private var theme: ReaderTheme {
        settings.readerTheme.shown(in: colorScheme)
    }

    private var shownColorScheme: ColorScheme {
        theme.isDark ? .dark : .light
    }

    private func open() async {
        guard controller == nil, !cannotOpen else {
            return
        }
        do {
            let readerBook = try await ReaderBook.open(book.fileURL)
            let controller = ReaderController(
                book: readerBook,
                language: book.language,
                location: book.position.map { ReaderLocation(chapter: $0.chapter, offset: $0.offset) },
                style: .book,
                colors: theme.colors,
                highlightColor: theme.highlightColor(settings.highlightColor),
                pageTurn: .slide
            )
            let isChromeShown = $isChromeShown
            controller.onPageTap = { withAnimation { isChromeShown.wrappedValue.toggle() } }
            let book = book
            let modelContext = modelContext
            let settings = settings
            controller.onHighlight = { range in
                Self.addHighlight(range, color: settings.highlightColor, to: book, in: modelContext)
            }
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
        controller.highlightColor = theme.highlightColor(settings.highlightColor)
    }

    private static func addHighlight(
        _ range: ReaderTextRange, color: HighlightColor, to book: Book, in modelContext: ModelContext
    ) {
        guard !book.highlights.contains(where: { $0.covers(range) }) else {
            return
        }
        let highlight = Highlight(range: range, color: color)
        modelContext.insert(highlight)
        book.highlights.append(highlight)
        do {
            try modelContext.save()
        } catch {
            logger.error("Saving a highlight failed: \(error.localizedDescription, privacy: .public)")
        }
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

private let logger = Logger(subsystem: "com.ione.scholia", category: "reader")

private struct HighlightPainter: View {
    let book: Book
    let controller: ReaderController
    let theme: ReaderTheme

    var body: some View {
        let highlights = book.highlights.map { $0.readerHighlight(color: theme.highlightColor($0.color)) }
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onChange(of: highlights, initial: true) { _, highlights in
                controller.highlights = highlights
            }
    }
}

#if DEBUG
    private struct PaintedDiagnostics: View {
        let identifier: String
        let count: Int

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier(identifier)
                .accessibilityLabel(Text(verbatim: "\(count)"))
        }
    }
#endif
