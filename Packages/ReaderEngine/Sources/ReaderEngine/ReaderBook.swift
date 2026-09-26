import Foundation
import ReadiumShared
import ReadiumStreamer

public final class ReaderBook {
    public let title: String?
    public let language: String?
    public let tableOfContents: [ReaderChapter]
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
        return tableOfContents.first { $0.location == start }
    }

    private static func chapters(in links: [Link], readingOrder: [Link]) -> [ReaderChapter] {
        links.flatMap { link in
            let chapter = readingOrder.firstIndexWithHREF(link.url().removingFragment()).flatMap { index in
                link.title.map { ReaderChapter(title: $0, location: ReaderLocation(chapter: index, offset: 0)) }
            }
            return [chapter].compactMap { $0 } + chapters(in: link.children, readingOrder: readingOrder)
        }
    }
}

public enum ReaderError: Error {
    case unreadable
    case protected
}
