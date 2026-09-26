import SwiftUI

public struct TranslationBubblePlacement: Layout {
    let anchor: CGRect
    let topLimit: CGFloat
    let gap: CGFloat

    public init(anchor: CGRect, topLimit: CGFloat, gap: CGFloat) {
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
            let above = anchor.minY - gap - size.height
            let y = above >= topLimit ? above : anchor.maxY + gap
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading,
                proposal: ProposedViewSize(size))
        }
    }
}
