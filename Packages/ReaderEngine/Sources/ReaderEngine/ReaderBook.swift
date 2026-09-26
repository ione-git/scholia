import Foundation
import Observation
import ReadiumShared
import ReadiumStreamer

@Observable
public final class ReaderBook {
    public let title: String?
    public let language: String?
    public private(set) var tableOfContents: [ReaderChapter]
    let url: URL
    let publication: Publication

    private init(url: URL, publication: Publication, tableOfContents: [ReaderChapter]) {
        self.url = url
        self.publication = publication
        self.tableOfContents = tableOfContents
        title = publication.metadata.title
        language = publication.metadata.languages.first
    }

    public static func open(_ url: URL) async throws(ReaderError) -> ReaderBook {
        guard let file = FileURL(url: url) else {
            throw .unreadable
        }
        let retriever = AssetRetriever(httpClient: DefaultHTTPClient())
        guard case .success(let asset) = await retriever.retrieve(url: file) else {
            throw .unreadable
        }
        let opener = PublicationOpener(parser: EPUBParser())
        guard case .success(let publication) = await opener.open(asset: asset, allowUserInteraction: false) else {
            throw .unreadable
        }
        guard !publication.isRestricted else {
            throw .protected
        }
        let contents = (try? await publication.tableOfContents().get()) ?? []
        return ReaderBook(
            url: url, publication: publication,
            tableOfContents: chapters(in: contents, readingOrder: publication.readingOrder))
    }

    public func chapter(containing location: ReaderLocation) -> ReaderChapter? {
        let start = tableOfContents.map(\.location).filter { $0 <= location }.max()
        return tableOfContents.last { $0.location == start }
    }

    func fragments(inChapter chapter: Int) -> [String] {
        tableOfContents.filter { $0.location.chapter == chapter }.compactMap(\.fragment)
    }

    func unresolvedFragments(inChapter chapter: Int) -> [String] {
        tableOfContents.filter { $0.location.chapter == chapter && !$0.isResolved }.compactMap(\.fragment)
    }

    func resolveFragments(_ offsets: [String: Int], inChapter chapter: Int) {
        for index in tableOfContents.indices
        where tableOfContents[index].location.chapter == chapter && !tableOfContents[index].isResolved {
            tableOfContents[index].location.offset = tableOfContents[index].fragment.flatMap { offsets[$0] } ?? 0
            tableOfContents[index].isResolved = true
        }
    }

    private static func chapters(in links: [Link], readingOrder: [Link]) -> [ReaderChapter] {
        entries(in: links, readingOrder: readingOrder).enumerated().map { index, entry in
            ReaderChapter(
                index: index, title: entry.title, location: ReaderLocation(chapter: entry.chapter, offset: 0),
                fragment: entry.fragment, isResolved: entry.fragment == nil)
        }
    }

    private typealias Entry = (title: String, chapter: Int, fragment: String?)

    private static func entries(in links: [Link], readingOrder: [Link]) -> [Entry] {
        links.flatMap { link in
            let url = link.url()
            let entry = readingOrder.firstIndexWithHREF(url.removingFragment()).flatMap { chapter in
                link.title.map { (title: $0, chapter: chapter, fragment: url.fragment) }
            }
            return [entry].compactMap { $0 } + entries(in: link.children, readingOrder: readingOrder)
        }
    }
}

public enum ReaderError: Error {
    case unreadable
    case protected
}
