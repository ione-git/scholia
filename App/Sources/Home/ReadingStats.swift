import Foundation

struct ReadingStats {
    let minutesRead: Int
    let goalMinutes: Int
    private let secondsPerPage: TimeInterval?

    init(sessions: [ReadingSession], today: DateInterval, goalMinutes: Int) {
        var secondsToday: TimeInterval = 0
        var seconds: TimeInterval = 0
        var pages = 0
        for session in sessions {
            seconds += max(session.end.timeIntervalSince(session.start), 0)
            pages += session.pages
            let overlap = min(session.end, today.end).timeIntervalSince(max(session.start, today.start))
            secondsToday += max(overlap, 0)
        }
        minutesRead = Int(secondsToday / 60)
        self.goalMinutes = goalMinutes
        secondsPerPage = pages > 0 ? seconds / Double(pages) : nil
    }

    var minutesToGo: Int { goalMinutes - minutesRead }

    var isGoalDone: Bool { minutesToGo <= 0 }

    var goalProgress: Double { min(Double(minutesRead) / Double(goalMinutes), 1) }

    func minutesLeft(in book: Book) -> Int? {
        guard let secondsPerPage, book.position != nil, !book.isFinished, let pagesLeft = book.pagesLeft,
            pagesLeft > 0
        else {
            return nil
        }
        return max(Int((Double(pagesLeft) * secondsPerPage / 60).rounded()), 1)
    }

    static func day(containing date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .day, for: date)!
    }
}
