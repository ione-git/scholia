import Foundation

public nonisolated struct EPUBMetadata: Sendable {
    public enum Failure: Error {
        case unreadable
        case protected
    }

    private enum Path {
        static let container = "META-INF/container.xml"
        static let encryption = "META-INF/encryption.xml"
    }

    private static let dublinCore = "http://purl.org/dc/elements/1.1/"
    private static let fontObfuscation: Set = ["http://www.idpf.org/2008/embedding", "http://ns.adobe.com/pdf/enc#RC"]

    public let title: String?
    public let author: String?
    public let language: String?
    public let cover: Data?

    @concurrent
    public static func read(from url: URL) async throws(Failure) -> EPUBMetadata {
        guard let archive = ZipArchive(url: url) else { throw .unreadable }
        if archive.contains(Path.encryption) {
            guard let encryption = archive.contents(of: Path.encryption).flatMap(MarkupElement.parse) else {
                throw .unreadable
            }
            let algorithms = encryption.descendants(named: "EncryptionMethod", namespace: nil).compactMap {
                $0.attributes["Algorithm"]
            }
            if algorithms.contains(where: { !fontObfuscation.contains($0) }) { throw .protected }
        }
        guard let container = archive.contents(of: Path.container).flatMap(MarkupElement.parse),
            let packagePath = container.descendants(named: "rootfile", namespace: nil).lazy
                .compactMap({ $0.attributes["full-path"] }).first,
            let package = archive.contents(of: packagePath).flatMap(MarkupElement.parse)
        else { throw .unreadable }
        return EPUBMetadata(
            title: text(of: "title", in: package), author: text(of: "creator", in: package),
            language: text(of: "language", in: package),
            cover: coverPath(in: package, at: packagePath).flatMap(archive.contents(of:)))
    }

    private static func text(of name: String, in package: MarkupElement) -> String? {
        package.descendants(named: name, namespace: dublinCore).lazy
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func coverPath(in package: MarkupElement, at packagePath: String) -> String? {
        let items = package.descendants(named: "item", namespace: nil)
        let coverID = package.descendants(named: "meta", namespace: nil)
            .first { $0.attributes["name"] == "cover" }?.attributes["content"]
        let item =
            items.first { $0.attributes["properties"]?.split(separator: " ").contains("cover-image") == true }
            ?? items.first { coverID != nil && $0.attributes["id"] == coverID }
        guard let href = item?.attributes["href"],
            let resolved = URL(string: href, relativeTo: URL(filePath: "/" + packagePath))
        else { return nil }
        return String(resolved.absoluteURL.standardized.path(percentEncoded: false).dropFirst())
    }
}
