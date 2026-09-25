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
        let count: Int?
        let identifier: String

        public init(_ value: Value, title: Text, count: Int?, identifier: String) {
            self.value = value
            self.title = title
            self.count = count
            self.identifier = identifier
        }
    }

    private static var inset: CGFloat { 2 }
    private static var countSpacing: CGFloat { 5 }

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
        return Button {
            selection = segment.value
        } label: {
            HStack(spacing: Self.countSpacing) {
                segment.title.foregroundStyle(.ink)
                if let count = segment.count {
                    Text(count, format: .number).foregroundStyle(.inkMuted)
                }
            }
            .textStyle(.subhead)
            .lineLimit(1)
            .padding(.horizontal, size == .compact ? .space3 : 0)
            .frame(maxWidth: size == .regular ? .infinity : nil)
            .frame(height: size.height)
            .background {
                if isSelected {
                    shape.fill(.surfaceCard).shadow(.card, in: shape)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(segment.identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
