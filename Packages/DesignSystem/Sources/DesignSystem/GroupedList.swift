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
                        ListHairline()
                    }
                }
            }
        }
        .groupedListCard()
    }
}

public struct LazyGroupedList<Data: RandomAccessCollection, Row: View>: View where Data.Element: Hashable {
    let data: Data
    let row: (Data.Element) -> Row

    public init(_ data: Data, @ViewBuilder row: @escaping (Data.Element) -> Row) {
        self.data = data
        self.row = row
    }

    public var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(data, id: \.self) { element in
                VStack(spacing: 0) {
                    row(element)
                    if element != data.last {
                        ListHairline()
                    }
                }
            }
        }
        .groupedListCard()
    }
}

private struct ListHairline: View {
    var body: some View {
        Rectangle().fill(.hairline).frame(height: .hairlineW)
    }
}

extension View {
    fileprivate func groupedListCard() -> some View {
        padding(.horizontal, .space4)
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

public struct ChapterRow: View {
    private static let barWidth: CGFloat = 3
    private static let barHeight: CGFloat = 22

    let title: Text
    let page: Int?
    let isCurrent: Bool

    public init(_ title: Text, page: Int?, isCurrent: Bool) {
        self.title = title
        self.page = page
        self.isCurrent = isCurrent
    }

    public var body: some View {
        HStack(spacing: .space3) {
            Capsule()
                .fill(isCurrent ? Color.accent : .clear)
                .frame(width: Self.barWidth, height: Self.barHeight)
            title
                .textStyle(isCurrent ? TextStyle.listSerif.weighted(TextStyle.title3.weight) : .listSerif)
                .foregroundStyle(.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let page {
                Text(page, format: .number)
                    .textStyle(.subhead)
                    .foregroundStyle(.inkMuted)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, .space3)
        .frame(minHeight: ListRow<EmptyView>.Height.control.value)
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

public struct ListRowCheckbox: View {
    private static let size: CGFloat = 24
    private static let checkSize: CGFloat = 14
    private static let checkStroke: CGFloat = 3
    private static let borderWidth: CGFloat = 1.5

    let isChecked: Bool

    public init(isChecked: Bool) {
        self.isChecked = isChecked
    }

    public var body: some View {
        ZStack {
            if isChecked {
                Circle().fill(.accent)
                IconView(icon: .check, size: Self.checkSize, stroke: Self.checkStroke)
                    .foregroundStyle(.onAccent)
            } else {
                Circle().strokeBorder(.inkFaint, lineWidth: Self.borderWidth)
            }
        }
        .frame(width: Self.size, height: Self.size)
        .accessibilityHidden(true)
    }
}

public struct ListActionRow: View {
    private static let iconSize: CGFloat = 20
    private static let iconStroke: CGFloat = 2
    private static let iconSpacing: CGFloat = 10

    let title: Text
    let icon: Icon

    public init(_ title: Text, icon: Icon) {
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: Self.iconSpacing) {
            IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
            title
                .textStyle(TextStyle.body.weighted(TextStyle.callout.weight))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.accent)
        .frame(minHeight: ListRow<EmptyView>.Height.regular.value)
        .contentShape(.rect)
    }
}
