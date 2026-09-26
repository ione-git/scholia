import ReaderEngine
import SwiftData
import SwiftUI

struct ReadingTime: ViewModifier {
    private static let idleLimit: TimeInterval = 5 * 60

    let controller: ReaderController?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var isOnScreen = false
    @State private var segment: Segment?

    func body(content: Content) -> some View {
        content
            .onAppear {
                isOnScreen = true
                update()
            }
            .onDisappear {
                isOnScreen = false
                update()
            }
            .onChange(of: scenePhase) { update() }
            .onChange(of: controller != nil) { update() }
            .onChange(of: controller?.page) { _, page in turn(to: page) }
            .onChange(of: controller?.word) { recordActivity() }
    }

    private static var now: Date {
        LaunchConfiguration.current.now ?? .now
    }

    private func update() {
        let isReading = isOnScreen && controller != nil && scenePhase == .active
        if isReading, segment == nil {
            let now = Self.now
            segment = Segment(start: now, lastActivity: now, pages: 0, page: controller?.page)
        } else if !isReading, let running = segment {
            segment = nil
            save(running, end: min(Self.now, running.lastActivity.addingTimeInterval(Self.idleLimit)))
        }
    }

    private func turn(to page: ReaderPage?) {
        recordActivity()
        if let previous = segment?.page, let page, page.count == previous.count, page.number == previous.number + 1 {
            segment?.pages += 1
        }
        segment?.page = page
    }

    private func recordActivity() {
        guard let running = segment else {
            return
        }
        let now = Self.now
        let idleEnd = running.lastActivity.addingTimeInterval(Self.idleLimit)
        if now > idleEnd {
            save(running, end: idleEnd)
            segment = Segment(start: now, lastActivity: now, pages: 0, page: running.page)
        } else {
            segment?.lastActivity = now
        }
    }

    private func save(_ segment: Segment, end: Date) {
        guard end > segment.start || segment.pages > 0 else {
            return
        }
        modelContext.insert(ReadingSession(start: segment.start, end: end, pages: segment.pages))
        try? modelContext.save()
    }
}

private struct Segment {
    var start: Date
    var lastActivity: Date
    var pages: Int
    var page: ReaderPage?
}
