import Foundation
import ReadiumShared
import ReadiumStreamer

public final class ReaderBook {
    public let title: String?
    public let language: String?
    let url: URL
    let publication: Publication

    private init(url: URL, publication: Publication) {
        self.url = url
        self.publication = publication
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
        return ReaderBook(url: url, publication: publication)
    }
}

public enum ReaderError: Error {
    case unreadable
    case protected
}
