import Foundation
import SwiftData

@Model
final class ReadingSession {
    var start: Date
    var end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}
