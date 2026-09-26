import Foundation
import SwiftData

@Model
final class ReadingSession {
    var start: Date
    var end: Date
    var pages: Int = 0

    init(start: Date, end: Date, pages: Int) {
        self.start = start
        self.end = end
        self.pages = pages
    }
}
