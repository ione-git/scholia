import SwiftUI

public struct GroupedSection<Content: View>: View {
    let title: Text
    let content: Content

    public init(_ title: Text, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space2) {
            title
                .textStyle(.labelCaps)
                .foregroundStyle(.inkMuted)
                .padding(.leading, .space4)
                .accessibilityAddTraits(.isHeader)
            GroupedList { content }
        }
    }
}

public struct GroupedList<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row
                    if row.id != rows.last?.id {
                        Rectangle().fill(.hairline).frame(height: .hairlineW)
                    }
                }
            }
        }
        .padding(.horizontal, .space4)
        .background(.surfaceCard, in: RoundedRectangle(cornerRadius: .radiusLg))
    }
}

public struct ListRow<Trailing: View>: View {
    public enum Height: Sendable {
        case regular
        case control

        var value: CGFloat {
            switch self {
            case .regular: 50
            case .control: 56
            }
        }
    }

    let title: Text
    let height: Height
    let trailing: Trailing

    public init(_ title: Text, height: Height, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.height = height
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: .space3) {
            title
                .textStyle(.body)
                .foregroundStyle(.ink)
            Spacer(minLength: 0)
            trailing
        }
        .frame(minHeight: height.value)
        .contentShape(.rect)
    }
}

public struct ListRowValue: View {
    let value: Text

    public init(_ value: Text) {
        self.value = value
    }

    public var body: some View {
        HStack(spacing: .space1) {
            value
                .textStyle(.body)
                .foregroundStyle(.inkMuted)
            ListRowChevron()
        }
    }
}

public struct ListRowChevron: View {
    private static let size: CGFloat = 18
    private static let stroke: CGFloat = 2

    public init() {}

    public var body: some View {
        IconView(icon: .chevron, size: Self.size, stroke: Self.stroke)
            .foregroundStyle(.inkFaint)
    }
}

public struct ListRowCheckmark: View {
    private static let size: CGFloat = 18
    private static let stroke: CGFloat = 2.6

    public init() {}

    public var body: some View {
        IconView(icon: .check, size: Self.size, stroke: Self.stroke)
            .foregroundStyle(.accent)
    }
}
