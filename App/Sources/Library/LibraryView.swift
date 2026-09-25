import DesignSystem
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Settings.self) private var settings
    @Query private var books: [Book]
    @State private var query = ""
    @State private var isMenuShown = false

    var body: some View {
        ScrollView {
            LibraryGrid(books: shownBooks)
                .padding(.horizontal, .space5)
                .padding(.top, .space5)
                .padding(.bottom, .space10)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) { header }
        .glassMenu(isPresented: $isMenuShown, alignment: .topTrailing) {
            LibraryMenu(isShown: $isMenuShown)
                .padding(.top, .controlH + .space2)
                .padding(.trailing, .space5)
        }
        .background(.surface)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var shownBooks: [Book] {
        let query = query.trimmingCharacters(in: .whitespaces)
        return settings.librarySort.sorted(query.isEmpty ? books : books.filter { $0.matches(query) })
    }

    private var header: some View {
        VStack(spacing: .space3) {
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
            .frame(height: .controlH)
            SearchField(
                text: $query, prompt: Text("Search titles and authors"), label: Text("Search titles and authors")
            )
            .accessibilityIdentifier("library.searchField")
        }
        .padding(.horizontal, .space5)
    }
}

private struct LibraryGrid: View {
    private static let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .leading),
        GridItem(.flexible(), spacing: 0, alignment: .center),
        GridItem(.flexible(), spacing: 0, alignment: .trailing),
    ]

    let books: [Book]

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: .space5) {
            ForEach(books) { book in
                VStack(alignment: .leading, spacing: .space2) {
                    BookCover(book: book, size: .library)
                        .accessibilityIdentifier("library.book.\(book.title)")
                    Text(book.title)
                        .textStyle(.caption)
                        .foregroundStyle(.ink)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
                .frame(width: BookCover.Size.library.width)
            }
        }
    }
}

private struct LibraryMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Settings.self) private var settings
    @Binding var isShown: Bool
    @State private var isSortShown = false

    var body: some View {
        GlassMenu {
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
                GlassMenuItem(Text("Select Books"), icon: .select) { isShown = false }
                    .accessibilityIdentifier("libraryMenu.selectBooks")
                GlassMenuItem(Text("New Collection"), icon: .newCollection) { isShown = false }
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
