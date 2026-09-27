import Foundation
import ReadiumShared

public nonisolated struct EPUBMetadata: Sendable {
    public let title: String?
    public let author: String?
    public let language: String?
    public let cover: Data?

    @concurrent
    public static func read(from url: URL) async throws(ReaderError) -> EPUBMetadata {
        let publication = try await Publication.open(url)
        let cover = await publication.linkWithRel(.cover).flatMap(publication.get)?.read()
        return EPUBMetadata(
            title: nonEmpty(publication.metadata.title), author: nonEmpty(publication.metadata.authors.first?.name),
            language: publication.metadata.languages.first, cover: cover.flatMap { try? $0.get() })
    }

    private static func nonEmpty(_ text: String?) -> String? {
        text?.isEmpty == false ? text : nil
    }
}
