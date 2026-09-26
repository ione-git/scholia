import DesignSystem
import SwiftUI

struct GoalPopover: View {
    let stats: ReadingStats

    var body: some View {
        HStack(spacing: .space3) {
            GoalRing(
                value: stats.goalProgress, size: .popover, isActive: false,
                center: Text(stats.minutesRead, format: .number))
            Group {
                if stats.isGoalDone {
                    Text("Goal done")
                } else {
                    Text("\(stats.minutesToGo) min to go")
                }
            }
            .textStyle(.title3)
            .foregroundStyle(.ink)
            .fixedSize()
        }
        .padding(.vertical, .space3)
        .padding(.leading, .space3)
        .padding(.trailing, .space4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityIdentifier("goal.summary")
        .popoverStyle()
    }

    private var label: Text {
        if stats.isGoalDone {
            Text("Today: goal done, \(stats.minutesRead) minutes read")
        } else {
            Text("Today: \(stats.minutesRead) minutes read, \(stats.minutesToGo) minutes to go")
        }
    }
}
