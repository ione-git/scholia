import Foundation
import Observation
import ReadiumShared

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
        let publication = try await Publication.open(url)
        let contents = (try? await publication.tableOfContents().get()) ?? []
        return ReaderBook(
            url: url, publication: publication,
            tableOfContents: chapters(in: contents, readingOrder: publication.readingOrder, depth: 0))
    }

    public func chapter(containing location: ReaderLocation) -> ReaderChapter? {
        indexOfChapter(containing: location).map { tableOfContents[$0] }
    }

    public func indexOfChapter(containing location: ReaderLocation) -> Int? {
        guard !hasUnknownOffsets(inChapter: location.chapter) else {
            return nil
        }
        guard let start = tableOfContents.compactMap(\.location).filter({ $0 <= location }).max() else {
            return nil
        }
        return tableOfContents.lastIndex { $0.location == start }
    }

    private func hasUnknownOffsets(inChapter chapter: Int) -> Bool {
        let chapters = tableOfContents.filter { $0.location?.chapter == chapter }
        return chapters.count > 1 && chapters.contains { $0.unresolvedFragment != nil }
    }

    func unresolvedFragments(inChapter chapter: Int) -> [String] {
        tableOfContents.filter { $0.location?.chapter == chapter }.compactMap(\.unresolvedFragment)
    }

    func resolveFragments(_ offsets: [String: Int], inChapter chapter: Int) {
        for index in tableOfContents.indices where tableOfContents[index].location?.chapter == chapter {
            if let fragment = tableOfContents[index].unresolvedFragment {
                tableOfContents[index].location?.offset = offsets[fragment] ?? 0
                tableOfContents[index].unresolvedFragment = nil
            }
        }
    }

    private static func chapters(in links: [Link], readingOrder: [Link], depth: Int) -> [ReaderChapter] {
        links.flatMap { link in
            let children = chapters(in: link.children, readingOrder: readingOrder, depth: depth + 1)
            guard let title = link.title else { return children }
            let url = link.url()
            let index = readingOrder.firstIndexWithHREF(url.removingFragment())
            guard index != nil || !children.isEmpty else { return children }
            let chapter = ReaderChapter(
                depth: depth, title: title,
                location: index.map { ReaderLocation(chapter: $0, offset: 0) },
                fragment: index == nil ? nil : url.fragment,
                unresolvedFragment: index == nil ? nil : url.fragment)
            return [chapter] + children
        }
    }
}
