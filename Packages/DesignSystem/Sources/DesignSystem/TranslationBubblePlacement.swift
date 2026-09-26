import SwiftUI

public struct TranslationBubblePlacement: Layout {
    private static let gap: CGFloat = 10

    let anchor: CGRect
    let topLimit: CGFloat

    public init(anchor: CGRect, topLimit: CGFloat) {
        self.anchor = anchor
        self.topLimit = topLimit
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let x = min(max(anchor.midX - size.width / 2, .space4), bounds.width - .space4 - size.width)
            let above = anchor.minY - Self.gap - size.height
            let y = above >= topLimit ? above : anchor.maxY + Self.gap
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading,
                proposal: ProposedViewSize(size))
        }
    }
}
