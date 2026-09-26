import SwiftUI

public struct GlassToolbar<Content: View>: View {
    private static var height: CGFloat { 56 }
    private static var inset: CGFloat { 6 }

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(subviews: content) { item in
                Spacer(minLength: 0)
                item
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Self.inset)
        .frame(height: Self.height)
        .glassEffect(.regular, in: .capsule)
    }
}

public struct GlassToolbarItem: View {
    private static let iconSize: CGFloat = 18
    private static let iconStroke: CGFloat = 2
    private static let spacing: CGFloat = 6

    let title: Text
    let icon: Icon
    let role: ButtonRole?
    let action: () -> Void

    public init(_ title: Text, icon: Icon, role: ButtonRole?, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: Self.spacing) {
                IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
                title
                    .textStyle(TextStyle.subhead.weighted(TextStyle.title3.weight))
                    .lineLimit(1)
            }
            .foregroundStyle(role == .destructive ? Color.danger : Color.ink)
            .padding(.horizontal, .space3)
            .frame(minHeight: .controlH)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
