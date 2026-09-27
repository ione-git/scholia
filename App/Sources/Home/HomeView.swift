import DesignSystem
import SwiftData
import SwiftUI

#if DEBUG
    import UniformTypeIdentifiers
#endif

struct HomeView: View {
    @Binding var path: NavigationPath
    @Binding var isPickingFile: Bool
    @Query(sort: [
        SortDescriptor(\Book.openedAt, order: .reverse), SortDescriptor(\Book.addedAt, order: .reverse),
        SortDescriptor(\Book.title),
    ])
    private var books: [Book]
    @Query private var sessions: [ReadingSession]
    @Environment(Settings.self) private var settings
    @State private var today = ReadingStats.day(containing: LaunchConfiguration.current.now ?? .now)
    @State private var isGoalShown = false
    #if DEBUG
        @State private var prototypeBook: PrototypeBook?
        @State private var isImporting = false
    #endif

    var body: some View {
        let stats = ReadingStats(sessions: sessions, today: today, goalMinutes: settings.dailyGoalMinutes)
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    header(stats)
                    if let hero = books.first {
                        HeroBook(book: hero, minutesLeft: stats.minutesLeft(in: hero))
                            .padding(.top, .space8)
                        Spacer(minLength: .space6)
                        LibraryShelf(count: books.count, books: Array(books.dropFirst()))
                            .padding(.bottom, .space8)
                    } else {
                        EmptyHome { isPickingFile = true }
                            .frame(maxHeight: .infinity)
                            .padding(.bottom, .controlH + proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
                    }
                }
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(.surface)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = ReadingStats.day(containing: LaunchConfiguration.current.now ?? .now)
        }
        #if DEBUG
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.epub]) { result in
                guard case .success(let picked) = result else {
                    return
                }
                Task { prototypeBook = PrototypeBook(url: try? await PrototypeBook.importedCopy(of: picked)) }
            }
            .fullScreenCover(item: $prototypeBook) { ReaderPrototype(url: $0.url) }
        #endif
    }

    private func header(_ stats: ReadingStats) -> some View {
        HStack(spacing: .space2) {
            wordmark
            goalRing(stats)
            Spacer(minLength: 0)
            GlassButton(.add, label: Text("Add a book"), size: .regular, isActive: false) {
                isPickingFile = true
            }
            .accessibilityIdentifier("home.addBook")
            GlassButton(.settings, label: Text("Settings"), size: .regular, isActive: false) {
                path.append(Route.settings)
            }
            .accessibilityIdentifier("home.settings")
        }
        .frame(height: .controlH)
        .padding(.horizontal, .space5)
    }

    private func goalRing(_ stats: ReadingStats) -> some View {
        Button {
            isGoalShown = true
        } label: {
            GoalRing(value: stats.goalProgress, size: .header, isActive: isGoalShown, center: nil)
                .frame(width: .controlH, height: .controlH)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            stats.isGoalDone
                ? Text("Today: goal reached, \(stats.minutesRead) minutes read")
                : Text("Today: \(stats.minutesRead) of \(stats.goalMinutes) minutes read")
        )
        .accessibilityValue(Text(stats.goalProgress, format: .percent.precision(.fractionLength(0))))
        .accessibilityIdentifier("home.goalRing")
        .frame(width: GoalRing.Size.header.width, height: GoalRing.Size.header.width)
        .popover(isPresented: $isGoalShown) {
            GoalPopover(stats: stats)
        }
    }

    private var wordmark: some View {
        Text("Scholia")
            .textStyle(.wordmark)
            .foregroundStyle(.ink)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("home.wordmark")
            #if DEBUG
                .contextMenu { debugMenu }
            #endif
    }

    #if DEBUG
        @ViewBuilder private var debugMenu: some View {
            Button("Token Gallery") { path.append(DebugRoute.tokenGallery) }
                .accessibilityIdentifier("home.tokenGallery")
            Button("Component Gallery") { path.append(DebugRoute.componentGallery) }
                .accessibilityIdentifier("home.componentGallery")
            Button("Launch Screen") { path.append(DebugRoute.launchScreen) }
                .accessibilityIdentifier("home.launchScreen")
            Button("Reader Prototype") { prototypeBook = Fixture.german.url.map(PrototypeBook.init(url:)) }
                .accessibilityIdentifier("home.readerPrototype")
            Button("Open EPUB…") { isImporting = true }
                .accessibilityIdentifier("home.openEPUB")
        }
    #endif
}

private struct EmptyHome: View {
    let addBook: () -> Void

    var body: some View {
        VStack(spacing: .space6) {
            CoverPlaceholder(label: Text("Add a book"), action: addBook)
                .accessibilityIdentifier("home.emptyCover")
            VStack(spacing: .space2) {
                Text("No books yet")
                    .textStyle(.titleBook)
                    .foregroundStyle(.ink)
                    .accessibilityIdentifier("home.emptyTitle")
                Text("Add an EPUB from Files, or share one to Scholia from any app.")
                    .textStyle(TextStyle.callout.weighted(TextStyle.body.weight))
                    .foregroundStyle(.inkMuted)
                    .accessibilityIdentifier("home.emptyMessage")
                    .padding(.horizontal, .space8)
            }
            .multilineTextAlignment(.center)
            Button("Add a Book", action: addBook)
                .buttonStyle(.solid(.compact))
                .accessibilityIdentifier("home.emptyAddBook")
        }
        .padding(.horizontal, .space5)
    }
}

private struct HeroBook: View {
    let book: Book
    let minutesLeft: Int?

    var body: some View {
        VStack(spacing: .space4) {
            NavigationLink(value: Route.reader(book)) {
                BookCover(book: book, size: .heroLarge)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.heroCover")
            VStack(spacing: .space1) {
                Text(book.title)
                    .textStyle(.titleBook)
                    .foregroundStyle(.ink)
                    .accessibilityIdentifier("home.heroTitle")
                if let author = book.author {
                    Text(author)
                        .textStyle(TextStyle.callout.weighted(TextStyle.body.weight))
                        .foregroundStyle(.inkMuted)
                        .accessibilityIdentifier("home.heroAuthor")
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, .space2)
            VStack(spacing: .space2) {
                ProgressBar(value: book.progress ?? 0)
                    .frame(width: BookCover.Size.heroLarge.width)
                    .accessibilityLabel(Text("Progress"))
                    .accessibilityIdentifier("home.heroProgress")
                if let minutesLeft {
                    TimeLeft(minutes: minutesLeft)
                }
            }
        }
        .padding(.horizontal, .space5)
    }
}

private struct TimeLeft: View {
    let minutes: Int

    var body: some View {
        text
            .textStyle(.footnote)
            .foregroundStyle(.inkMuted)
            .accessibilityLabel(spokenText)
            .accessibilityIdentifier("home.heroTimeLeft")
    }

    private var spokenText: Text {
        let duration = Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        return Text("\(duration) left")
    }

    private var text: Text {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 {
            return Text("\(rest) min left")
        }
        if rest == 0 {
            return Text("\(hours) h left")
        }
        return Text("\(hours) h \(rest) min left")
    }
}

private struct LibraryShelf: View {
    let count: Int
    let books: [Book]

    var body: some View {
        VStack(alignment: .leading, spacing: .space3) {
            NavigationLink(value: Route.library) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Library")
                        .textStyle(.section)
                        .foregroundStyle(.ink)
                    Spacer()
                    HStack(spacing: .space1) {
                        Text("All \(count)")
                            .textStyle(TextStyle.callout.weighted(TextStyle.body.weight))
                            .foregroundStyle(.inkMuted)
                        ListRowChevron()
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, .space5)
            .accessibilityIdentifier("home.library")
            if !books.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: .space3) {
                        ForEach(books) { book in
                            NavigationLink(value: Route.reader(book)) {
                                BookCover(book: book, size: .row)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("home.book.\(book.title)")
                        }
                    }
                }
                .contentMargins(.horizontal, .space5)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#if DEBUG
    private struct PrototypeBook: Identifiable {
        let url: URL?

        var id: URL? { url }
    }

    extension PrototypeBook {
        @concurrent
        fileprivate nonisolated static func importedCopy(of picked: URL) async throws -> URL {
            let copy = URL.temporaryDirectory.appending(path: picked.lastPathComponent)
            let isAccessing = picked.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    picked.stopAccessingSecurityScopedResource()
                }
            }
            try? FileManager.default.removeItem(at: copy)
            try FileManager.default.copyItem(at: picked, to: copy)
            return copy
        }
    }
#endif
