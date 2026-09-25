#if DEBUG
    import DesignSystem
    import ReaderEngine
    import SwiftUI

    struct ReaderPrototype: View {
        let url: URL

        @Environment(\.dismiss) private var dismiss
        @Environment(\.colorScheme) private var colorScheme
        @State private var controller: ReaderController?
        @State private var cannotOpen = false
        @State private var chosenTheme: ReaderTheme?
        @State private var isChromeShown = false

        var body: some View {
            ZStack {
                theme.page.ignoresSafeArea()
                if let controller {
                    ReaderView(controller: controller)
                        .ignoresSafeArea()
                    page(controller)
                } else if cannotOpen {
                    failed
                }
            }
            .environment(\.colorScheme, theme.isDark ? .dark : .light)
            .statusBarHidden()
            .task { await open() }
            .onChange(of: theme) { recolor() }
        }

        private var theme: ReaderTheme {
            chosenTheme ?? (colorScheme == .dark ? .night : .paper)
        }

        private func page(_ controller: ReaderController) -> some View {
            ZStack {
                if let word = controller.word {
                    RoundedRectangle(cornerRadius: .radiusXs)
                        .fill(.wordTap)
                        .frame(width: word.rect.width, height: word.rect.height)
                        .position(x: word.rect.midX, y: word.rect.midY)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityIdentifier("reader.wordTint")
                }
                VStack(spacing: .space3) {
                    if let title = controller.book.title {
                        Text(title)
                            .textStyle(.labelCaps)
                            .foregroundStyle(.inkMuted)
                            .lineLimit(1)
                            .frame(height: .controlH)
                            .padding(.horizontal, .space5 + .controlH)
                            .padding(.top, .navTop)
                            .accessibilityIdentifier("reader.runningHead")
                    }
                    Spacer()
                    if let word = controller.word {
                        wordPanel(word)
                    }
                    if isChromeShown {
                        controls(controller)
                    }
                    if let page = controller.page {
                        Text("\(page.number) of \(page.count)")
                            .textStyle(.caption)
                            .foregroundStyle(.inkMuted)
                            .padding(.bottom, .space8 + .space1)
                            .accessibilityIdentifier("reader.pageCounter")
                            .accessibilityValue(page.location.chapter)
                    }
                }
                .frame(maxWidth: .infinity)
                .background { HighlightDiagnostics(highlights: controller.highlights) }
            }
            .ignoresSafeArea()
        }

        private func wordPanel(_ word: ReaderWord) -> some View {
            VStack(alignment: .leading, spacing: .space1) {
                Text(word.text)
                    .textStyle(.title3)
                    .foregroundStyle(.ink)
                    .accessibilityIdentifier("reader.word")
                Text(word.sentence)
                    .textStyle(.footnote)
                    .foregroundStyle(.inkMuted)
                    .accessibilityIdentifier("reader.sentence")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.space4)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: .radiusXl))
            .padding(.horizontal, .space5)
        }

        private func controls(_ controller: ReaderController) -> some View {
            VStack(spacing: .space3) {
                HStack(spacing: .space2) {
                    ForEach(ReaderTheme.allCases, id: \.self) { option in
                        choice(option.title, isSelected: option == theme, identifier: "reader.theme.\(option.rawValue)")
                        {
                            chosenTheme = option
                        }
                    }
                }
                HStack(spacing: .space2) {
                    ForEach(ReaderPageTurn.allCases, id: \.self) { option in
                        choice(
                            option.title, isSelected: option == controller.pageTurn,
                            identifier: "reader.pageTurn.\(option.rawValue)"
                        ) {
                            controller.pageTurn = option
                        }
                    }
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                        .accessibilityIdentifier("reader.close")
                }
            }
            .padding(.horizontal, .space5)
        }

        @ViewBuilder
        private func choice(
            _ title: LocalizedStringResource, isSelected: Bool, identifier: String, action: @escaping () -> Void
        ) -> some View {
            let button = Button(action: action) {
                Text(title).textStyle(.subhead).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier(identifier)
            if isSelected {
                button
                    .buttonStyle(.glassProminent)
                    .tint(.ink)
                    .foregroundStyle(.onInk)
                    .accessibilityAddTraits(.isSelected)
            } else {
                button.buttonStyle(.glass)
            }
        }

        private var failed: some View {
            VStack(spacing: .space4) {
                Text("This book can't be opened.")
                    .textStyle(.body)
                    .foregroundStyle(.ink)
                    .accessibilityIdentifier("reader.failure")
                Button("Close") { dismiss() }
                    .buttonStyle(.glass)
                    .accessibilityIdentifier("reader.close")
            }
        }

        private func open() async {
            do {
                let book = try await ReaderBook.open(url)
                let controller = ReaderController(
                    book: book,
                    style: ReaderStyle(
                        font: ReaderFont(
                            family: DesignSystem.serifFamilyName,
                            regular: DesignSystem.serifFontURL,
                            italic: DesignSystem.serifItalicFontURL
                        ),
                        fontSize: TextStyle.readingBody.size,
                        lineHeight: TextStyle.readingBody.lineHeight,
                        sideMargin: .space7,
                        topMargin: .navTop + .controlH + .space8,
                        minimumBottomMargin: .controlH + .space10,
                        highlightRadius: .radiusXs
                    ),
                    colors: colors,
                    highlightColor: highlightColor,
                    pageTurn: .slide,
                    highlightTitle: String(localized: "Highlight")
                )
                controller.onPageTap = { isChromeShown.toggle() }
                self.controller = controller
            } catch {
                cannotOpen = true
            }
        }

        private func recolor() {
            guard let controller else {
                return
            }
            controller.colors = colors
            controller.highlightColor = highlightColor
            controller.highlights = controller.highlights.map { highlight in
                var highlight = highlight
                highlight.color = highlightColor
                return highlight
            }
        }

        private var colors: ReaderColors {
            ReaderColors(
                page: UIColor(theme.page),
                text: UIColor(theme.text),
                selection: UIColor(theme.isDark ? ColorToken.selectionHandle.dark : ColorToken.selectionHandle.light)
            )
        }

        private var highlightColor: UIColor {
            UIColor(theme.isDark ? ColorToken.highlightYellow.dark : ColorToken.highlightYellow.light)
        }
    }

    private struct HighlightDiagnostics: View {
        let highlights: [ReaderHighlight]

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.highlights")
                .accessibilityLabel(Text(verbatim: highlights.map(\.range.text).joined(separator: "\n")))
                .accessibilityValue(Text(verbatim: "\(highlights.count)"))
        }
    }

    extension ReaderTheme {
        fileprivate var isDark: Bool { self == .night || self == .black }

        fileprivate var title: LocalizedStringResource {
            switch self {
            case .paper: "Paper"
            case .sepia: "Sepia"
            case .night: "Night"
            case .black: "Black"
            }
        }
    }

    extension ReaderPageTurn {
        fileprivate var title: LocalizedStringResource {
            switch self {
            case .slide: "Slide"
            case .curl: "Curl"
            }
        }
    }
#endif
