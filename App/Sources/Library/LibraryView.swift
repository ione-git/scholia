import DesignSystem
import SwiftData
import SwiftUI

struct LibraryView: View {
    private enum Sheet {
        case addToCollection([Book])
        case info(Book)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings
    @Query private var books: [Book]
    @Query(sort: BookCollection.order) private var collections: [BookCollection]
    @State private var query = ""
    @State private var shownCollection: BookCollection?
    @State private var isMenuShown = false
    @State private var isNamingCollection = false
    @State private var selection: Set<Book>?
    @State private var sheet: Sheet?
    @State private var removal: [Book] = []

    var body: some View {
        ScrollView {
            LibraryGrid(
                books: shownBooks, selection: selection, removal: $removal, onToggle: toggle, onAction: perform
            )
            .padding(.horizontal, .space5)
            .padding(.top, .space5)
            .padding(.bottom, .space10)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) { header }
        .safeAreaBar(edge: .bottom) {
            if let selection {
                selectionBar(settings.librarySort.sorted(Array(selection)))
            }
        }
        .glassMenu(isPresented: $isMenuShown, alignment: .topTrailing) {
            LibraryMenu(isShown: $isMenuShown, isNamingCollection: $isNamingCollection) { selection = [] }
                .padding(.top, .controlH + .space2)
                .padding(.trailing, .space5)
        }
        .newCollectionAlert(isPresented: $isNamingCollection) { _ in }
        .modalSheet(isPresented: isShowingSheet) { sheetContent }
        .background(.surface)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var shownBooks: [Book] {
        let query = query.trimmingCharacters(in: .whitespaces)
        let books = shownCollection?.books ?? self.books
        return settings.librarySort.sorted(query.isEmpty ? books : books.filter { $0.matches(query) })
    }

    private var header: some View {
        VStack(spacing: .space3) {
            Group {
                if let selection {
                    selectionHeader(count: selection.count)
                } else {
                    navigationRow
                }
            }
            .frame(height: .controlH)
            .padding(.horizontal, .space5)
            SearchField(
                text: $query, prompt: Text("Search titles and authors"), label: Text("Search titles and authors")
            )
            .accessibilityIdentifier("library.searchField")
            .padding(.horizontal, .space5)
            if !collections.isEmpty {
                chips
            }
        }
    }

    private var navigationRow: some View {
        HStack(spacing: .space2) {
            GlassButton(.back, label: Text("Back to Home"), size: .regular, isActive: false) { dismiss() }
                .accessibilityIdentifier("library.back")
            Spacer(minLength: 0)
            Text("Library")
                .textStyle(.section)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("library.title")
            Spacer(minLength: 0)
            GlassButton(
                .more, label: isMenuShown ? Text("Close menu") : Text("More"), size: .regular,
                isActive: isMenuShown
            ) {
                isMenuShown.toggle()
            }
            .accessibilityIdentifier("library.more")
        }
    }

    private func selectionHeader(count: Int) -> some View {
        ZStack {
            Group {
                if count == 0 {
                    Text("Select Books")
                } else {
                    Text("\(count) Selected")
                }
            }
            .textStyle(.title3)
            .foregroundStyle(.ink)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("librarySelection.title")
            HStack(spacing: 0) {
                Button("Cancel") { selection = nil }
                    .buttonStyle(.sheetCancel)
                    .accessibilityIdentifier("librarySelection.cancel")
                Spacer(minLength: 0)
                Button("Done") { selection = nil }
                    .buttonStyle(.sheetDone)
                    .accessibilityIdentifier("librarySelection.done")
            }
        }
    }

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .space2) {
                Chip(Text("All"), count: books.count, isSelected: shownCollection == nil) { shownCollection = nil }
                    .accessibilityIdentifier("library.allChip")
                ForEach(collections) { collection in
                    Chip(
                        Text(collection.name), count: collection.books.count, isSelected: shownCollection == collection
                    ) {
                        shownCollection = collection
                    }
                    .accessibilityIdentifier("library.collectionChip.\(collection.name)")
                }
                NewCollectionChip(label: Text("New collection")) { isNamingCollection = true }
                    .accessibilityIdentifier("library.newCollectionChip")
            }
        }
        .contentMargins(.horizontal, .space5)
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("library.collections")
    }

    private func selectionBar(_ selected: [Book]) -> some View {
        let marksUnread = !selected.isEmpty && selected.allSatisfy(\.isFinished)
        return GlassToolbar {
            GlassToolbarItem(Text("Collection"), icon: .collection, role: nil) {
                sheet = .addToCollection(selected)
            }
            .accessibilityIdentifier("librarySelection.collection")
            GlassToolbarItem(marksUnread ? Text("Unread") : Text("Finished"), icon: .select, role: nil) {
                selected.setFinished(!marksUnread)
                try? modelContext.save()
                selection = nil
            }
            .accessibilityIdentifier("librarySelection.finished")
            GlassToolbarItem(Text("Remove"), icon: .trash, role: .destructive) {
                removal = selected
            }
            .accessibilityIdentifier("librarySelection.remove")
            .removeBooksDialog($removal, for: selected) { selection = nil }
        }
        .disabled(selected.isEmpty)
        .padding(.horizontal, .space5)
    }

    private var isShowingSheet: Binding<Bool> {
        Binding(
            get: { sheet != nil },
            set: { isShown in
                if !isShown {
                    sheet = nil
                }
            })
    }

    @ViewBuilder private var sheetContent: some View {
        switch sheet {
        case .addToCollection(let books):
            if let first = books.first {
                collectionSheet(books, cover: BookCover(book: first, size: .thumbnail))
            }
        case .info(let book):
            BookInfoView(book: book)
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private func collectionSheet(_ books: [Book], cover: BookCover) -> some View {
        let shared = Set(collections.filter { collection in books.allSatisfy { $0.collections.contains(collection) } })
        let chosen = Binding(
            get: { shared },
            set: { (chosen: Set<BookCollection>) in
                books.updateCollections(adding: chosen.subtracting(shared), removing: shared.subtracting(chosen))
                try? modelContext.save()
                selection = nil
            })
        if books.count == 1, let book = books.first {
            AddToCollectionSheet(cover: cover, title: book.title, author: book.author, selection: chosen)
        } else {
            AddToCollectionSheet(
                cover: cover, title: books.map(\.title).formatted(.list(type: .and, width: .narrow)),
                author: String(localized: "\(books.count) books"), selection: chosen)
        }
    }

    private func toggle(_ book: Book) {
        guard var selected = selection else { return }
        if selected.remove(book) == nil {
            selected.insert(book)
        }
        selection = selected
    }

    private func perform(_ action: BookAction, on book: Book) {
        switch action {
        case .addToCollection:
            sheet = .addToCollection([book])
        case .toggleFinished:
            [book].setFinished(!book.isFinished)
            try? modelContext.save()
        case .info:
            sheet = .info(book)
        case .remove:
            removal = [book]
        }
    }
}

private struct LibraryGrid: View {
    private static let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .leading),
        GridItem(.flexible(), spacing: 0, alignment: .center),
        GridItem(.flexible(), spacing: 0, alignment: .trailing),
    ]

    let books: [Book]
    let selection: Set<Book>?
    @Binding var removal: [Book]
    let onToggle: (Book) -> Void
    let onAction: (BookAction, Book) -> Void

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: .space5) {
            ForEach(books) { book in
                cell(book)
            }
        }
    }

    @ViewBuilder
    private func cell(_ book: Book) -> some View {
        if let selection {
            let isSelected = selection.contains(book)
            Button {
                onToggle(book)
            } label: {
                titled(book) {
                    BookCover(book: book, size: .library).selectable(isSelected: isSelected)
                }
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("library.book.\(book.title)")
        } else {
            titled(book) {
                NavigationLink(value: Route.reader(book)) {
                    BookCover(book: book, size: .library)
                }
                .buttonStyle(.plain)
                .contextMenu { BookMenu(book: book) { onAction($0, book) } }
                .accessibilityIdentifier("library.book.\(book.title)")
                .removeBooksDialog($removal, for: [book]) {}
            }
        }
    }

    private func titled(_ book: Book, @ViewBuilder cover: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space2) {
            cover()
            Text(book.title)
                .textStyle(.caption)
                .foregroundStyle(.ink)
                .lineLimit(1)
                .accessibilityHidden(true)
        }
        .frame(width: BookCover.Size.library.width)
    }
}

private struct LibraryMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings
    @Binding var isShown: Bool
    @Binding var isNamingCollection: Bool
    let onSelectBooks: () -> Void
    @State private var isSortShown = false

    var body: some View {
        GlassMenu(size: .regular) {
            if isSortShown {
                GlassMenuHeader(Text("Sort by")) { isSortShown = false }
                    .accessibilityIdentifier("librarySortMenu.back")
                ForEach(LibrarySort.allCases, id: \.self) { sort in
                    GlassMenuOption(Text(sort.title), isSelected: sort == settings.librarySort) {
                        settings.librarySort = sort
                        try? modelContext.save()
                        isShown = false
                    }
                    .accessibilityIdentifier("librarySortMenu.\(sort.rawValue)")
                }
            } else {
                GlassMenuItem(Text("Select Books"), icon: .select) {
                    isShown = false
                    onSelectBooks()
                }
                .accessibilityIdentifier("libraryMenu.selectBooks")
                GlassMenuItem(Text("New Collection"), icon: .newCollection) {
                    isShown = false
                    isNamingCollection = true
                }
                .accessibilityIdentifier("libraryMenu.newCollection")
                GlassMenuItem(
                    Text("Sort by \(Text(settings.librarySort.shortTitle).foregroundStyle(.inkMuted))"), icon: .sort
                ) {
                    isSortShown = true
                }
                .accessibilityIdentifier("libraryMenu.sortBy")
            }
        }
    }
}
