import DesignSystem
import ReaderEngine
import SwiftData
import SwiftUI

struct ReadingView: View {
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled
    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings
    @Environment(OrientationLock.self) private var orientationLock
    @State private var controller: ReaderController?
    @State private var cannotOpen = false
    @State private var isChromeShown = false
    @State private var isMenuShown = false
    @State private var indexTab: ReaderIndexTab?
    @State private var isSettingsShown = false
    @State private var pickedTheme: ReaderTheme?
    @State private var window = WindowReference()
    @State private var transition = ThemeTransition()

    var body: some View {
        ZStack {
            theme.page.ignoresSafeArea()
            if let controller {
                ReaderView(controller: controller)
                    .ignoresSafeArea()
                    #if DEBUG
                        .background { ReaderAppearanceDiagnostics(controller: controller) }
                    #endif
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
        }
        .background { WindowAnchor(reference: window) }
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
            ReaderSettingsSheet(theme: theme, pick: pick)
                .preferredColorScheme(shownColorScheme)
        }
        .task { await open() }
        .task(id: appearance) {
            controller?.highlightColor = theme.highlightColor
            await controller?.apply(appearance)
            if !Task.isCancelled {
                transition.reveal()
            }
        }
        .onChange(of: theme) {
            if scenePhase != .background {
                transition.begin(in: window.window)
            }
        }
        .onChange(of: colorScheme) {
            if scenePhase != .background {
                pickedTheme = nil
            }
        }
        .onChange(of: isSettingsShown) { controller?.looksUpWords = !isSettingsShown }
        .onChange(of: settings.locksRotation) { lockRotation() }
        .onChange(of: controller?.location) { _, location in save(location) }
        .onChange(of: controller?.page) { _, page in save(page) }
        .onDisappear {
            guard indexTab == nil else {
                return
            }
            transition.end()
            orientationLock.unlock(in: window.window)
        }
    }

    private var theme: ReaderTheme {
        pickedTheme ?? settings.readerTheme.shown(in: colorScheme)
    }

    private var shownColorScheme: ColorScheme {
        theme.isDark ? .dark : .light
    }

    private var appearance: ReaderAppearance {
        ReaderAppearance(settings: settings, theme: theme)
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
                appearance: appearance,
                typefaces: ReaderFont.allCases.map(\.typeface),
                highlightColor: theme.highlightColor,
                highlightTitle: String(localized: "Highlight")
            )
            let isChromeShown = $isChromeShown
            let isSettingsShown = $isSettingsShown
            controller.onPageTap = {
                if isSettingsShown.wrappedValue {
                    isSettingsShown.wrappedValue = false
                } else {
                    withAnimation { isChromeShown.wrappedValue.toggle() }
                }
            }
            self.controller = controller
            lockRotation()
            book.openedAt = LaunchConfiguration.current.now ?? .now
            try? modelContext.save()
        } catch {
            cannotOpen = true
        }
    }

    private func pick(_ picked: ReaderTheme) {
        if picked != theme {
            transition.begin(in: window.window)
        }
        pickedTheme = picked.shown(in: colorScheme) == picked ? nil : picked
        settings.update(\.readerTheme, to: picked, in: modelContext)
    }

    private func lockRotation() {
        if settings.locksRotation {
            orientationLock.lock(in: window.window)
        } else {
            orientationLock.unlock(in: window.window)
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

#if DEBUG
    private struct ReaderAppearanceDiagnostics: View {
        let controller: ReaderController

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.readerAppearance")
                .accessibilityLabel(Text(verbatim: style))
                .accessibilityValue(Text(verbatim: span))
        }

        private var style: String {
            guard let style = controller.renderedStyle else {
                return ""
            }
            return [
                style.background, style.text, style.fontFamily,
                "\(style.fontSize.formatted())/\(style.lineHeight.formatted())",
            ]
            .joined(separator: " · ")
        }

        private var span: String {
            guard let span = controller.pageSpan else {
                return ""
            }
            return "\(span.chapter):\(span.start)-\(span.end)"
        }
    }
#endif
