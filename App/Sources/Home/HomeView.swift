import DesignSystem
import SwiftData
import SwiftUI

#if DEBUG
    import UniformTypeIdentifiers
#endif

struct HomeView: View {
    @Binding var path: NavigationPath
    @Query(sort: [
        SortDescriptor(\Book.openedAt, order: .reverse), SortDescriptor(\Book.addedAt, order: .reverse),
        SortDescriptor(\Book.title),
    ])
    private var books: [Book]
    #if DEBUG
        @State private var prototypeBook: PrototypeBook?
        @State private var isImporting = false
    #endif

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    header
                    if let hero = books.first {
                        HeroBook(book: hero)
                            .padding(.top, .space8)
                        Spacer(minLength: .space6)
                        LibraryShelf(count: books.count, books: Array(books.dropFirst()))
                            .padding(.bottom, .space8)
                    }
                }
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(.surface)
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.epub]) { result in
                guard case .success(let picked) = result else {
                    return
                }
                prototypeBook = try? PrototypeBook(importing: picked)
            }
            .fullScreenCover(item: $prototypeBook) { ReaderPrototype(url: $0.url) }
        #endif
    }

    private var header: some View {
        HStack(spacing: .space2) {
            wordmark
            GoalRing(value: 0)
                .accessibilityLabel(Text("Daily goal"))
                .accessibilityIdentifier("home.goalRing")
            Spacer(minLength: 0)
            GlassButton(.add, label: Text("Add a book"), size: .regular, isActive: false) {}
                .accessibilityIdentifier("home.addBook")
            GlassButton(.settings, label: Text("Settings"), size: .regular, isActive: false) {
                path.append(Route.settings)
            }
            .accessibilityIdentifier("home.settings")
        }
        .frame(height: .controlH)
        .padding(.horizontal, .space5)
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

private struct HeroBook: View {
    let book: Book

    var body: some View {
        VStack(spacing: .space4) {
            BookCover(
                title: book.title, author: book.author, color: BookCover.generatedColor(for: book.title),
                image: book.coverImage, size: .heroLarge, isFinished: book.isFinished, finishedValue: Text("Finished")
            )
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
            ProgressBar(value: 0)
                .frame(width: BookCover.Size.heroLarge.width)
                .accessibilityLabel(Text("Progress"))
                .accessibilityIdentifier("home.heroProgress")
        }
        .padding(.horizontal, .space5)
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
                            BookCover(
                                title: book.title, author: book.author,
                                color: BookCover.generatedColor(for: book.title), image: book.coverImage, size: .row,
                                isFinished: book.isFinished, finishedValue: Text("Finished")
                            )
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

extension Book {
    fileprivate var coverImage: Image? {
        cover.flatMap(UIImage.init(data:)).map(Image.init(uiImage:))
    }
}

#if DEBUG
    private struct PrototypeBook: Identifiable {
        let url: URL

        var id: URL { url }
    }

    extension PrototypeBook {
        fileprivate init(importing picked: URL) throws {
            let copy = URL.temporaryDirectory.appending(path: picked.lastPathComponent)
            let isAccessing = picked.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    picked.stopAccessingSecurityScopedResource()
                }
            }
            try? FileManager.default.removeItem(at: copy)
            try FileManager.default.copyItem(at: picked, to: copy)
            url = copy
        }
    }
#endif
