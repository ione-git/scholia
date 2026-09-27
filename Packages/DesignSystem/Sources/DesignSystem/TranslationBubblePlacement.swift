import SwiftUI

public struct TranslationBubblePlacement: Layout {
    public enum Gap: Sendable {
        case bubble
        case pill
        case selectionMenu
        case highlightMenu

        private static let bubbleGap: CGFloat = 10
        private static let selectionMenuGap: CGFloat = 18
        private static let highlightMenuGap: CGFloat = 14

        var value: CGFloat {
            switch self {
            case .bubble: Self.bubbleGap
            case .pill: .space2
            case .selectionMenu: Self.selectionMenuGap
            case .highlightMenu: Self.highlightMenuGap
            }
        }
    }

    let anchor: CGRect
    let topLimit: CGFloat
    let gap: Gap

    public init(anchor: CGRect, topLimit: CGFloat, gap: Gap) {
        self.anchor = anchor
        self.topLimit = topLimit
        self.gap = gap
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width - 2 * .space4, height: nil))
            let x = min(max(anchor.midX - size.width / 2, .space4), bounds.width - .space4 - size.width)
            let above = anchor.minY - gap.value - size.height
            let y = above >= topLimit ? above : anchor.maxY + gap.value
            let clamped = max(min(y, bounds.height - .space4 - size.height), topLimit)
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + clamped), anchor: .topLeading,
                proposal: ProposedViewSize(size))
        }
    }
}
