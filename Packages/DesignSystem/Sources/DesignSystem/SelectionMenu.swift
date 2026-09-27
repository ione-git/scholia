import SwiftUI

private let menuInset: CGFloat = 4

public struct SelectionMenu<Content: View>: View {
    private static var minWidth: CGFloat { 270 }
    private static var minHeight: CGFloat { 46 }
    private static var separatorHeight: CGFloat { 22 }

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        Group(subviews: content) { items in
            EqualWidthRow(minSize: CGSize(width: Self.minWidth - 2 * menuInset, height: Self.minHeight)) {
                ForEach(items) { item in
                    item.overlay(alignment: .trailing) {
                        if item.id != items.last?.id {
                            Rectangle()
                                .fill(.hairline)
                                .frame(width: .hairlineW, height: Self.separatorHeight)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, menuInset)
        .glassEffect(.regular.tint(.surfaceGlassStrong), in: .capsule)
        .accessibilityElement(children: .contain)
    }
}

public struct SelectionMenuItem: View {
    let title: Text
    let isPrimary: Bool
    let action: () -> Void

    public init(_ title: Text, isPrimary: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            title
                .textStyle(isPrimary ? TextStyle.callout.weighted(TextStyle.title3.weight) : TextStyle.callout)
                .foregroundStyle(.ink)
                .lineLimit(1)
                .padding(.horizontal, .space2)
                .frame(maxWidth: .infinity, minHeight: .controlH, maxHeight: .infinity)
        }
        .buttonStyle(SelectionMenuItemStyle())
    }
}

private struct SelectionMenuItemStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .background {
                if configuration.isPressed {
                    Capsule()
                        .fill(.controlFill)
                        .padding(.vertical, menuInset)
                }
            }
    }
}

private struct EqualWidthRow: Layout {
    let minSize: CGSize

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return CGSize(
            width: max((sizes.map(\.width).max() ?? 0) * CGFloat(subviews.count), minSize.width),
            height: max(sizes.map(\.height).max() ?? 0, minSize.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width / CGFloat(max(subviews.count, 1))
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(index) * width, y: bounds.minY), anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: bounds.height))
        }
    }
}
