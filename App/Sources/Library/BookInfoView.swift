import DesignSystem
import SwiftData
import SwiftUI

struct BookInfoView: View {
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title: String
    @State private var author: String
    @State private var language: String?
    @State private var collections: Set<BookCollection>
    @State private var resetsProgress = false
    @State private var isChoosingLanguage = false
    @State private var isChoosingCollections = false
    @State private var fileSize: Int?

    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author ?? "")
        _language = State(initialValue: book.language)
        _collections = State(initialValue: Set(book.collections))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: .space4) {
                SheetHeader(Text("Book Info")) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.sheetCancel)
                        .accessibilityIdentifier("bookInfo.cancel")
                } trailing: {
                    Button("Done", action: save)
                        .buttonStyle(.sheetDone)
                        .disabled(trimmedTitle.isEmpty)
                        .accessibilityIdentifier("bookInfo.done")
                }
                ScrollView {
                    VStack(spacing: .space5) {
                        file
                        GroupedList {
                            ListTextField(Text("Title"), text: $title)
                                .accessibilityIdentifier("bookInfo.title")
                            ListTextField(Text("Author"), text: $author)
                                .accessibilityIdentifier("bookInfo.author")
                        }
                        GroupedList {
                            Button {
                                isChoosingLanguage = true
                            } label: {
                                ListRow(Text("Language"), height: .regular) {
                                    ListRowValue(language.map { Text(language: $0, isDetected: false) } ?? Text("None"))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("bookInfo.language")
                            Button {
                                isChoosingCollections = true
                            } label: {
                                ListRow(Text("Collections"), height: .regular) {
                                    ListRowValue(collectionsValue)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("bookInfo.collections")
                        }
                        GroupedList {
                            ListRow(Text("Progress"), height: .regular) { value(progressValue) }
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("bookInfo.progress")
                            ListRow(Text("Highlights"), height: .regular) {
                                value(Text(book.highlights.count, format: .number))
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("bookInfo.highlights")
                            Button {
                                resetsProgress = true
                            } label: {
                                ListRow(Text("Reset reading progress").foregroundStyle(Color.accent), height: .regular)
                                {
                                    EmptyView()
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasProgress)
                            .accessibilityIdentifier("bookInfo.resetProgress")
                        }
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
                LanguagePicker(selection: $language, detected: nil)
            }
        }
        .task {
            fileSize = await Storage.fileSize(at: book.fileURL)
        }
        .modalSheet(isPresented: $isChoosingCollections) {
            AddToCollectionSheet(
                cover: cover(size: .thumbnail), title: trimmedTitle, author: trimmedAuthor, selection: $collections)
        }
    }

    private var file: some View {
        VStack(spacing: .space2) {
            cover(size: .grid)
                .accessibilityIdentifier("bookInfo.cover")
            fileInfo
                .textStyle(.caption)
                .foregroundStyle(.inkMuted)
                .accessibilityIdentifier("bookInfo.fileInfo")
        }
    }

    private func cover(size: BookCover.Size) -> BookCover {
        BookCover(
            title: title, author: trimmedAuthor, color: BookCover.generatedColor(for: title),
            image: book.cover.flatMap(UIImage.init(data:)).map(Image.init(uiImage:)), size: size,
            isFinished: book.isFinished, finishedValue: Text("Finished"))
    }

    private var fileInfo: Text {
        let added = book.addedAt.formatted(.dateTime.day().month(.abbreviated).year())
        guard let fileSize else {
            return Text("EPUB · added \(added)")
        }
        return Text("EPUB · \(Int64(fileSize).formatted(.byteCount(style: .file))) · added \(added)")
    }

    private var collectionsValue: Text {
        guard !collections.isEmpty else { return Text("None") }
        return Text(
            collections.sorted(using: BookCollection.order).map(\.name).formatted(.list(type: .and, width: .narrow)))
    }

    private var hasProgress: Bool {
        book.position != nil && !resetsProgress
    }

    private var progressValue: Text {
        hasProgress ? Text("In progress") : Text("Not started")
    }

    private func value(_ text: Text) -> some View {
        text
            .textStyle(.body)
            .foregroundStyle(.inkMuted)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAuthor: String? {
        let author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return author.isEmpty ? nil : author
    }

    private func save() {
        guard !trimmedTitle.isEmpty, let language else { return }
        book.title = trimmedTitle
        book.author = trimmedAuthor
        book.language = language
        book.collections = Array(collections)
        if resetsProgress {
            book.position = nil
        }
        try? context.save()
        dismiss()
    }
}
