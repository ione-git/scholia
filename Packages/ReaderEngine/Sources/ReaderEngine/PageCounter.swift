import CryptoKit
import Foundation
import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

struct ChapterPages: Codable, Equatable {
    var count: Int
    var fragments: [String: FragmentPage]
}

struct FragmentPage: Codable, Equatable {
    var offset: Int
    var page: Int
}

final class PageCounter: NSObject {
    let navigator: EPUBNavigatorViewController
    private let book: ReaderBook
    private let contentInset: () -> UIEdgeInsets
    private var received: [PageCount] = []
    private var waiting: CheckedContinuation<PageCount?, Never>?
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

    func count() async -> [ChapterPages]? {
        await withTaskCancellationHandler {
            var counts: [ChapterPages] = []
            for (chapter, link) in book.publication.readingOrder.enumerated() {
                if !counts.isEmpty {
                    guard await navigator.go(to: link, options: NavigatorGoOptions(animated: false)) else {
                        return nil
                    }
                }
                guard let count = await nextCount() else {
                    return nil
                }
                let fragments = await fragmentPages(book.fragments(inChapter: chapter), in: count.webView)
                guard !isCancelled else {
                    return nil
                }
                counts.append(ChapterPages(count: count.pages, fragments: fragments))
            }
            return counts
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel() }
        }
    }

    private func fragmentPages(_ fragments: [String], in webView: WKWebView?) async -> [String: FragmentPage] {
        guard
            !fragments.isEmpty, let webView,
            let offsets = try? await webView.callAsyncJavaScript(
                "return scholia.offsetsOfElements(ids)", arguments: ["ids": fragments], contentWorld: .page)
                as? [String: Int]
        else {
            return [:]
        }
        var pages: [String: FragmentPage] = [:]
        for (fragment, offset) in offsets {
            if let page = try? await webView.callAsyncJavaScript(
                "return scholia.pageOfOffset(offset)", arguments: ["offset": offset], contentWorld: .page) as? Int
            {
                pages[fragment] = FragmentPage(offset: offset, page: page)
            }
        }
        return pages
    }

    private func nextCount() async -> PageCount? {
        guard !isCancelled else {
            return nil
        }
        guard received.isEmpty else {
            return received.removeFirst()
        }
        return await withCheckedContinuation { waiting = $0 }
    }

    fileprivate func receive(_ count: PageCount) {
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
            WKUserScript(source: ReaderViewController.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
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
        if let pages = message.body as? Int {
            counter?.receive(PageCount(pages: pages, webView: message.webView))
        }
    }
}

private struct PageCount {
    var pages: Int
    weak var webView: WKWebView?
}

public enum PageCountCache {
    private static let directory = URL.cachesDirectory.appending(path: "PageCounts", directoryHint: .isDirectory)

    public static func removeAll() throws {
        if FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: directory)
        }
    }

    static func key(book: ReaderBook, style: ReaderStyle, size: CGSize) -> String {
        let fileSize = (try? book.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return [
            book.url.lastPathComponent, "\(fileSize)", style.font.family, "\(style.fontSize)", "\(style.lineHeight)",
            "\(style.paragraphIndent)", "\(style.sideMargin)", "\(style.topMargin)", "\(style.minimumBottomMargin)",
            "\(size.width)", "\(size.height)",
        ]
        .joined(separator: "|")
    }

    static func counts(for key: String) -> [ChapterPages]? {
        guard let data = try? Data(contentsOf: file(for: key)) else {
            return nil
        }
        return try? JSONDecoder().decode([ChapterPages].self, from: data)
    }

    static func store(_ counts: [ChapterPages], for key: String) {
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
