import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    final class ReadingSession {
        var start: Date
        var end: Date

        init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }
    }
}
