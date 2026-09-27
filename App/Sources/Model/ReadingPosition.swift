import ReaderEngine

nonisolated struct ReadingPosition: Codable, Hashable {
    var chapter: Int
    var offset: Int
}

@MainActor
extension ReadingPosition {
    var location: ReaderLocation {
        ReaderLocation(chapter: chapter, offset: offset)
    }
}
