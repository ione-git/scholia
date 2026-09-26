import SwiftData
import SwiftUI

extension View {
    func newCollectionAlert(isPresented: Binding<Bool>, onCreate: @escaping (BookCollection) -> Void) -> some View {
        modifier(NewCollectionAlert(isPresented: isPresented, onCreate: onCreate))
    }
}

private struct NewCollectionAlert: ViewModifier {
    @Binding var isPresented: Bool
    let onCreate: (BookCollection) -> Void

    @Environment(\.modelContext) private var context
    @Query private var collections: [BookCollection]
    @State private var name = ""

    func body(content: Content) -> some View {
        content.alert(Text("New Collection"), isPresented: $isPresented) {
            TextField("Collection name", text: $name)
            Button("Cancel", role: .cancel) { name = "" }
                .accessibilityIdentifier("newCollection.cancel")
            Button("Create", action: create)
                .disabled(newName == nil)
                .accessibilityIdentifier("newCollection.create")
        }
    }

    private var newName: String? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let isTaken = collections.contains { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
        return name.isEmpty || isTaken ? nil : name
    }

    private func create() {
        guard let newName else { return }
        let collection = BookCollection(name: newName, createdAt: LaunchConfiguration.current.now ?? .now)
        context.insert(collection)
        try? context.save()
        name = ""
        onCreate(collection)
    }
}
