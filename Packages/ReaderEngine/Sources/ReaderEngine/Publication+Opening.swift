import Foundation
import ReadiumShared
import ReadiumStreamer

nonisolated extension Publication {
    private static let fontObfuscation: Set = ["http://www.idpf.org/2008/embedding", "http://ns.adobe.com/pdf/enc#RC"]

    nonisolated(nonsending) static func open(_ url: URL) async throws(ReaderError) -> Publication {
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
        let isEncrypted = (publication.readingOrder + publication.resources).contains { link in
            link.properties.encryption.map { !fontObfuscation.contains($0.algorithm) } ?? false
        }
        guard !publication.isRestricted, !isEncrypted else {
            throw .protected
        }
        return publication
    }
}
