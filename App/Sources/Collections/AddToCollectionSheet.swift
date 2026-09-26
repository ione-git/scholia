import DesignSystem
import SwiftData
import SwiftUI

struct AddToCollectionSheet: View {
    let cover: BookCover
    let title: String
    let author: String?
    @Binding var selection: Set<BookCollection>

    @Environment(\.dismiss) private var dismiss
    @Query(sort: BookCollection.order) private var collections: [BookCollection]
    @State private var checked: Set<BookCollection>
    @State private var isNamingCollection = false

    init(cover: BookCover, title: String, author: String?, selection: Binding<Set<BookCollection>>) {
        self.cover = cover
        self.title = title
        self.author = author
        _selection = selection
        _checked = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(Text("Add to Collection")) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.sheetCancel)
                    .accessibilityIdentifier("addToCollection.cancel")
            } trailing: {
                Button("Done") {
                    selection = checked
                    dismiss()
                }
                .buttonStyle(.sheetDone)
                .accessibilityIdentifier("addToCollection.done")
            }
            .padding(.horizontal, .space5)
            .padding(.top, .space6)
            .padding(.bottom, .space3)
            ScrollView {
                VStack(spacing: .space4) {
                    book
                    if !collections.isEmpty {
                        GroupedList {
                            ForEach(collections) { collection in
                                row(collection)
                            }
                        }
                    }
                    GroupedList {
                        Button {
                            isNamingCollection = true
                        } label: {
                            ListActionRow(Text("New Collection…"), icon: .add)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("addToCollection.newCollection")
                    }
                }
                .padding(.horizontal, .space5)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .newCollectionAlert(isPresented: $isNamingCollection) { checked.insert($0) }
    }

    private var book: some View {
        HStack(spacing: .space3) {
            cover
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .textStyle(TextStyle.listSerif.weighted(TextStyle.titleCard.weight))
                    .foregroundStyle(.ink)
                    .lineLimit(2)
                    .accessibilityIdentifier("addToCollection.bookTitle")
                if let author {
                    Text(author)
                        .textStyle(.footnote)
                        .foregroundStyle(.inkMuted)
                        .accessibilityIdentifier("addToCollection.bookAuthor")
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func row(_ collection: BookCollection) -> some View {
        let isChecked = checked.contains(collection)
        return Button {
            if isChecked {
                checked.remove(collection)
            } else {
                checked.insert(collection)
            }
        } label: {
            ListRow(Text(collection.name), height: .regular) {
                ListRowCheckbox(isChecked: isChecked)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
        .accessibilityIdentifier("addToCollection.collection.\(collection.name)")
    }
}
