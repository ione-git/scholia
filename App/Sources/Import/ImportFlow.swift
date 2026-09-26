import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

struct ImportFlow: ViewModifier {
    private struct IncomingFile: Equatable {
        let url: URL
        let source: PendingBook.Source
    }

    @Binding var isPickingFile: Bool
    @State private var incoming: IncomingFile?
    @State private var pending: PendingBook?
    @State private var failure: ImportFailure?

    func body(content: Content) -> some View {
        content
            .modalSheet(isPresented: isShowingBook) {
                if let pending {
                    AddBookView(book: pending, onCancel: { discard() }, onAdded: { self.pending = nil })
                        .id(pending.id)
                        .importFailureAlert(isPresented: isShowingFailure(overBook: true), failure: failure)
                }
            }
            .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.epub]) { result in
                if case .success(let url) = result {
                    incoming = IncomingFile(url: url, source: .files)
                }
            }
            .onOpenURL { url in
                incoming = IncomingFile(url: url, source: .otherApp)
            }
            .task(id: incoming) {
                guard let incoming else { return }
                do throws(ImportFailure) {
                    let staged = try await PendingBook.stage(incoming.url, from: incoming.source)
                    discard()
                    pending = staged
                } catch {
                    failure = error
                }
                self.incoming = nil
            }
            .importFailureAlert(isPresented: isShowingFailure(overBook: false), failure: failure)
    }

    private var isShowingBook: Binding<Bool> {
        Binding(
            get: { pending != nil },
            set: { isShown in
                if !isShown {
                    discard()
                }
            })
    }

    private func isShowingFailure(overBook: Bool) -> Binding<Bool> {
        Binding(
            get: { failure != nil && (pending != nil) == overBook },
            set: { isShown in
                if !isShown {
                    failure = nil
                }
            })
    }

    private func discard() {
        guard let pending else { return }
        self.pending = nil
        Task { await pending.discard() }
    }
}

extension View {
    fileprivate func importFailureAlert(isPresented: Binding<Bool>, failure: ImportFailure?) -> some View {
        alert(Text("Can’t Add Book"), isPresented: isPresented, presenting: failure) { _ in
            Button("OK") {}
        } message: { failure in
            failure.message
        }
    }
}

extension ImportFailure {
    fileprivate var message: Text {
        switch reason {
        case .unreadable: Text("“\(fileName)” is damaged or is not an EPUB file.")
        case .protected: Text("“\(fileName)” is protected by DRM. Scholia can open only DRM-free books.")
        }
    }
}
