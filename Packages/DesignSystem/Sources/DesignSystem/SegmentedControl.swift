import SwiftUI

public struct SegmentedControl<Value: Hashable>: View {
    public enum Size: Sendable {
        case regular
        case compact

        var height: CGFloat {
            switch self {
            case .regular: 36
            case .compact: 30
            }
        }
    }

    public struct Segment {
        let value: Value
        let title: Text
        let icon: Icon?
        let count: Int?
        let identifier: String

        public init(_ value: Value, title: Text, count: Int?, identifier: String) {
            self.value = value
            self.title = title
            icon = nil
            self.count = count
            self.identifier = identifier
        }

        public init(_ value: Value, icon: Icon, label: Text, identifier: String) {
            self.value = value
            title = label
            self.icon = icon
            count = nil
            self.identifier = identifier
        }
    }

    private static var inset: CGFloat { 2 }
    private static var countSpacing: CGFloat { 5 }
    private static var edgeOffset: CGFloat { 1 }
    private static var edgeBlur: CGFloat { 3 }
    private static var iconSize: CGFloat { 20 }
    private static var iconStroke: CGFloat { 2 }

    @Binding var selection: Value
    let size: Size
    let segments: [Segment]

    public init(selection: Binding<Value>, size: Size, segments: [Segment]) {
        _selection = selection
        self.size = size
        self.segments = segments
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(segments, id: \.value) { segment in
                button(segment)
            }
        }
        .padding(Self.inset)
        .background(.controlFill, in: RoundedRectangle(cornerRadius: .radiusMd))
    }

    private func button(_ segment: Segment) -> some View {
        let isSelected = segment.value == selection
        let shape = RoundedRectangle(cornerRadius: .radiusMd - Self.inset)
        let button = Button {
            selection = segment.value
        } label: {
            Group {
                if let icon = segment.icon {
                    IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
                        .foregroundStyle(.ink)
                } else {
                    HStack(spacing: Self.countSpacing) {
                        segment.title.foregroundStyle(.ink)
                            .textStyle(isSelected ? TextStyle.subhead.weighted(TextStyle.title3.weight) : .subhead)
                        if let count = segment.count {
                            Text(count, format: .number).foregroundStyle(.inkMuted)
                        }
                    }
                    .textStyle(.subhead)
                    .lineLimit(1)
                }
            }
            .padding(.horizontal, size == .compact ? .space3 : 0)
            .frame(maxWidth: size == .regular ? .infinity : nil)
            .frame(height: size.height)
            .background {
                if isSelected {
                    shape.fill(.surfaceCard)
                        .shadow(color: .controlBorder, radius: Self.edgeBlur / 2, y: Self.edgeOffset)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        return Group {
            if segment.icon == nil {
                button
            } else {
                button.accessibilityLabel(segment.title)
            }
        }
        .accessibilityIdentifier(segment.identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
