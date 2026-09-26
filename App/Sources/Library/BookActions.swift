import DesignSystem
import SwiftData
import SwiftUI

enum BookAction {
    case addToCollection
    case toggleFinished
    case info
    case remove
}

struct BookMenu: View {
    let book: Book
    let action: (BookAction) -> Void

    var body: some View {
        Button {
            action(.addToCollection)
        } label: {
            Label {
                Text("Add to Collection")
            } icon: {
                Icon.collection.menuImage
            }
        }
        .accessibilityIdentifier("bookMenu.addToCollection")
        Button {
            action(.toggleFinished)
        } label: {
            Label {
                book.isFinished ? Text("Mark as Unread") : Text("Mark as Finished")
            } icon: {
                Icon.select.menuImage
            }
        }
        .accessibilityIdentifier("bookMenu.finished")
        Button {
            action(.info)
        } label: {
            Label {
                Text("Book Info")
            } icon: {
                Icon.info.menuImage
            }
        }
        .accessibilityIdentifier("bookMenu.info")
        Divider()
        Button(role: .destructive) {
            action(.remove)
        } label: {
            Label {
                Text("Remove from Library")
            } icon: {
                Icon.trash.menuImage
            }
        }
        .accessibilityIdentifier("bookMenu.remove")
    }
}

extension [Book] {
    func setFinished(_ isFinished: Bool) {
        for book in self {
            book.isFinished = isFinished
        }
    }

    func updateCollections(adding added: Set<BookCollection>, removing removed: Set<BookCollection>) {
        for book in self {
            book.collections.removeAll { removed.contains($0) }
            book.collections.append(contentsOf: added.filter { !book.collections.contains($0) })
        }
    }
}

extension View {
    func removeBooksDialog(
        _ removal: Binding<[Book]>, for books: [Book], onRemove: @escaping () -> Void
    ) -> some View {
        modifier(RemoveBooksDialog(removal: removal, books: books, onRemove: onRemove))
    }
}

private struct RemoveBooksDialog: ViewModifier {
    @Binding var removal: [Book]
    let books: [Book]
    let onRemove: () -> Void

    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.confirmationDialog(title, isPresented: isPresented, titleVisibility: .visible) {
            Button("Remove", role: .destructive, action: remove)
                .accessibilityIdentifier("removeBooks.remove")
        } message: {
            message
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { !books.isEmpty && removal == books },
            set: { isShown in
                if !isShown {
                    removal = []
                }
            })
    }

    private var title: Text {
        if books.count == 1, let book = books.first {
            Text("Remove “\(book.title)” from your library?")
        } else {
            Text("Remove \(books.count) books from your library?")
        }
    }

    private var message: Text {
        let highlights = books.map(\.highlights.count).reduce(0, +)
        return switch (books.count == 1, highlights) {
        case (true, 0): Text("The book file will be deleted from this iPhone.")
        case (true, _): Text("The book file and its \(highlights) highlights will be deleted from this iPhone.")
        case (false, 0): Text("The book files will be deleted from this iPhone.")
        case (false, _): Text("The book files and their \(highlights) highlights will be deleted from this iPhone.")
        }
    }

    private func remove() {
        Task {
            await Storage.removeFiles(at: books.map(\.fileURL))
            for book in books {
                context.delete(book)
            }
            try? context.save()
            onRemove()
        }
    }
}
