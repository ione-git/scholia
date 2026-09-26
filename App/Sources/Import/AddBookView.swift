import DesignSystem
import SwiftData
import SwiftUI

struct AddBookView: View {
    let book: PendingBook
    let onCancel: () -> Void
    let onAdded: () -> Void

    @Environment(\.modelContext) private var context
    @State private var title: String
    @State private var author: String
    @State private var language: String?
    @State private var isChoosingLanguage = false
    @State private var collections: Set<BookCollection> = []
    @State private var isChoosingCollections = false
    @State private var isAdding = false
    @State private var isShowingSaveFailure = false

    init(book: PendingBook, onCancel: @escaping () -> Void, onAdded: @escaping () -> Void) {
        self.book = book
        self.onCancel = onCancel
        self.onAdded = onAdded
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author ?? "")
        _language = State(initialValue: book.language)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: .space4) {
                SheetHeader(Text("Add Book")) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.sheetCancel)
                        .accessibilityIdentifier("addBook.cancel")
                } trailing: {
                    EmptyView()
                }
                ScrollView {
                    VStack(spacing: .space5) {
                        file
                        GroupedList {
                            ListTextField(Text("Title"), text: $title)
                                .accessibilityIdentifier("addBook.title")
                            ListTextField(Text("Author"), text: $author)
                                .accessibilityIdentifier("addBook.author")
                        }
                        GroupedList {
                            Button {
                                isChoosingLanguage = true
                            } label: {
                                ListRow(Text("Language"), height: .regular) {
                                    ListRowValue(languageValue)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addBook.language")
                            Button {
                                isChoosingCollections = true
                            } label: {
                                ListRow(Text("Collection"), height: .regular) {
                                    ListRowValue(collectionValue)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addBook.collection")
                        }
                        Button("Add to Library", action: add)
                            .buttonStyle(.solid)
                            .disabled(draft == nil || isAdding)
                            .accessibilityIdentifier("addBook.add")
                    }
                    .padding(.bottom, .space10)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, .space5)
            .padding(.top, .space7)
            .background(.surface)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isChoosingLanguage) {
                LanguagePicker(selection: $language, detected: book.language)
            }
        }
        .modalSheet(isPresented: $isChoosingCollections) {
            AddToCollectionSheet(
                cover: cover(size: .thumbnail), title: title, author: trimmedAuthor, selection: $collections)
        }
        .alert(Text("Can’t Add Book"), isPresented: $isShowingSaveFailure) {
            Button("OK") {}
        } message: {
            Text("The book could not be saved. Try again.")
        }
    }

    private var file: some View {
        VStack(spacing: .space2) {
            cover(size: .grid)
                .accessibilityIdentifier("addBook.cover")
            fileInfo
                .textStyle(.caption)
                .foregroundStyle(.inkMuted)
                .accessibilityIdentifier("addBook.fileInfo")
        }
    }

    private func cover(size: BookCover.Size) -> BookCover {
        BookCover(
            title: title, author: trimmedAuthor, color: BookCover.generatedColor(for: title),
            image: book.coverImage.map(Image.init(uiImage:)), size: size, isFinished: false,
            finishedValue: Text("Finished"))
    }

    private var fileInfo: Text {
        let size = Int64(book.size).formatted(.byteCount(style: .file))
        switch book.source {
        case .files: return Text("EPUB · \(size) · from Files")
        case .otherApp: return Text("EPUB · \(size)")
        }
    }

    private var languageValue: Text {
        guard let language else { return Text("None") }
        return Text(language: language, isDetected: language == book.language)
    }

    private var collectionValue: Text {
        guard !collections.isEmpty else { return Text("None") }
        return Text(
            collections.sorted(using: BookCollection.order).map(\.name).formatted(.list(type: .and, width: .narrow)))
    }

    private var trimmedAuthor: String? {
        let author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return author.isEmpty ? nil : author
    }

    private var draft: (title: String, author: String?, language: String)? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let language else { return nil }
        return (title, trimmedAuthor, language)
    }

    private func add() {
        guard let draft else { return }
        isAdding = true
        Task {
            guard let fileName = try? await book.moveToLibrary() else {
                fail()
                return
            }
            let added = Book(
                fileName: fileName, title: draft.title, author: draft.author, language: draft.language,
                cover: book.cover, addedAt: LaunchConfiguration.current.now ?? .now)
            context.insert(added)
            added.collections = Array(collections)
            do {
                try context.save()
                onAdded()
            } catch {
                context.delete(added)
                await book.moveOutOfLibrary()
                fail()
            }
        }
    }

    private func fail() {
        isAdding = false
        isShowingSaveFailure = true
    }
}
