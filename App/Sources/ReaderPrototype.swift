#if DEBUG
    import DesignSystem
    import ReaderEngine
    import SwiftUI

    struct ReaderPrototype: View {
        let url: URL?

        @Environment(\.dismiss) private var dismiss
        @Environment(\.colorScheme) private var colorScheme
        @Environment(Settings.self) private var settings
        @State private var controller: ReaderController?
        @State private var cannotOpen = false
        @State private var chosenTheme: ReaderTheme?
        @State private var pageTurn = ReaderPageTurn.slide
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
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("reader.page")
            .environment(\.colorScheme, theme.isDark ? .dark : .light)
            .statusBarHidden()
            .task { await open() }
            .task(id: appearance) {
                recolor()
                await controller?.apply(appearance)
            }
        }

        private var theme: ReaderTheme {
            chosenTheme ?? (colorScheme == .dark ? .night : .paper)
        }

        private var appearance: ReaderAppearance {
            ReaderAppearance(
                style: ReaderStyle(
                    font: settings.readerFont, sizeStep: settings.textSizeStep, spacing: settings.lineSpacing),
                colors: theme.colors, pageTurn: pageTurn)
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
                            .accessibilityValue(String(page.chapter))
                    }
                }
                .frame(maxWidth: .infinity)
                .background {
                    HighlightDiagnostics(
                        highlights: controller.highlights, paintedHighlights: controller.paintedHighlights)
                }
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
                    ForEach([ReaderPageTurn.slide, .curl], id: \.self) { option in
                        choice(
                            option.title, isSelected: option == controller.appearance.pageTurn,
                            identifier: "reader.pageTurn.\(option.rawValue)"
                        ) {
                            pageTurn = option
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
                guard let url else {
                    throw ReaderError.unreadable
                }
                let book = try await ReaderBook.open(url)
                let controller = ReaderController(
                    book: book,
                    location: nil,
                    appearance: appearance,
                    typefaces: ReaderFont.allCases.map(\.typeface),
                    highlightColor: theme.highlightColor,
                    highlightTitle: String(localized: "Highlight")
                )
                let isChromeShown = $isChromeShown
                controller.onPageTap = { isChromeShown.wrappedValue.toggle() }
                self.controller = controller
            } catch {
                cannotOpen = true
            }
        }

        private func recolor() {
            guard let controller else {
                return
            }
            controller.highlightColor = theme.highlightColor
            controller.highlights = controller.highlights.map { highlight in
                var highlight = highlight
                highlight.color = theme.highlightColor
                return highlight
            }
        }
    }

    private struct HighlightDiagnostics: View {
        let highlights: [ReaderHighlight]
        let paintedHighlights: Int

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.highlights")
                .accessibilityLabel(Text(verbatim: highlights.map(\.range.text).joined(separator: "\n")))
                .accessibilityValue(Text(verbatim: "\(highlights.count)"))
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.paintedHighlights")
                .accessibilityLabel(Text(verbatim: "\(paintedHighlights)"))
        }
    }

    extension ReaderPageTurn {
        fileprivate var title: LocalizedStringResource {
            switch self {
            case .slide: "Slide"
            case .curl: "Curl"
            case .fade: "Fade"
            case .scroll: "Scroll"
            }
        }
    }
#endif
