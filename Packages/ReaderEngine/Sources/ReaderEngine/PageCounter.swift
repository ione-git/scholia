import CryptoKit
import Foundation
import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

final class PageCounter: NSObject {
    let navigator: EPUBNavigatorViewController
    private let book: ReaderBook
    private let contentInset: () -> UIEdgeInsets
    private var received: [Int] = []
    private var waiting: CheckedContinuation<Int?, Never>?
    private var isCancelled = false

    init(
        book: ReaderBook, configuration: EPUBNavigatorViewController.Configuration,
        contentInset: @escaping () -> UIEdgeInsets
    ) {
        var configuration = configuration
        configuration.preloadPreviousPositionCount = 0
        configuration.preloadNextPositionCount = 0
        self.book = book
        self.contentInset = contentInset
        navigator = try! EPUBNavigatorViewController(
            publication: book.publication, initialLocation: nil, config: configuration)
        super.init()
        navigator.delegate = self
    }

    func count() async -> [Int]? {
        await withTaskCancellationHandler {
            var counts: [Int] = []
            for link in book.publication.readingOrder {
                if !counts.isEmpty {
                    guard await navigator.go(to: link, options: NavigatorGoOptions(animated: false)) else {
                        return nil
                    }
                }
                guard let count = await nextCount() else {
                    return nil
                }
                counts.append(count)
            }
            return counts
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel() }
        }
    }

    private func nextCount() async -> Int? {
        guard !isCancelled else {
            return nil
        }
        guard received.isEmpty else {
            return received.removeFirst()
        }
        return await withCheckedContinuation { waiting = $0 }
    }

    fileprivate func receive(_ count: Int) {
        guard let waiting else {
            received.append(count)
            return
        }
        self.waiting = nil
        waiting.resume(returning: count)
    }

    private func cancel() {
        isCancelled = true
        waiting?.resume(returning: nil)
        waiting = nil
    }

    private static let script = try! String(
        contentsOf: Bundle.module.url(forResource: "page-count", withExtension: "js")!, encoding: .utf8)
}

extension PageCounter: EPUBNavigatorDelegate {
    func navigator(_ navigator: any Navigator, presentError error: NavigatorError) {}

    func navigatorContentInset(_ navigator: any VisualNavigator) -> UIEdgeInsets? {
        contentInset()
    }

    func navigator(
        _ navigator: EPUBNavigatorViewController, setupUserScripts userContentController: WKUserContentController
    ) {
        userContentController.addUserScript(
            WKUserScript(source: Self.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        userContentController.add(PageCountMessages(counter: self), name: "pageCount")
    }
}

private final class PageCountMessages: NSObject, WKScriptMessageHandler {
    private weak var counter: PageCounter?

    init(counter: PageCounter) {
        self.counter = counter
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let count = message.body as? Int {
            counter?.receive(count)
        }
    }
}

enum PageCountCache {
    private static let directory = URL.cachesDirectory.appending(path: "PageCounts", directoryHint: .isDirectory)

    static func key(book: ReaderBook, style: ReaderStyle, size: CGSize) -> String {
        let fileSize = (try? book.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return [
            book.url.lastPathComponent, "\(fileSize)", style.font.family, "\(style.fontSize)", "\(style.lineHeight)",
            "\(style.sideMargin)", "\(style.topMargin)", "\(style.minimumBottomMargin)", "\(size.width)",
            "\(size.height)",
        ]
        .joined(separator: "|")
    }

    static func counts(for key: String) -> [Int]? {
        guard let data = try? Data(contentsOf: file(for: key)) else {
            return nil
        }
        return try? JSONDecoder().decode([Int].self, from: data)
    }

    static func store(_ counts: [Int], for key: String) {
        guard let data = try? JSONEncoder().encode(counts) else {
            return
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(for: key), options: .atomic)
    }

    private static func file(for key: String) -> URL {
        let name = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: "\(name).json")
    }
}
