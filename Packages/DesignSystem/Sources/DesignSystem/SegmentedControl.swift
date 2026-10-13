import SwiftUI

public struct SegmentedControl<Value: Hashable>: View {
    public enum Size: Sendable {
        case regular
        case compact
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

    @Binding var selection: Value
    let size: Size
    let segments: [Segment]

    public init(selection: Binding<Value>, size: Size, segments: [Segment]) {
        _selection = selection
        self.size = size
        self.segments = segments
    }

    public var body: some View {
        Picker(selection: $selection) {
            ForEach(segments, id: \.value) { segment in
                label(segment)
                    .tag(segment.value)
                    .accessibilityIdentifier(segment.identifier)
            }
        } label: {
            Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .fixedSize(horizontal: size == .compact, vertical: false)
    }

    @ViewBuilder
    private func label(_ segment: Segment) -> some View {
        if let icon = segment.icon {
            icon.menuImage.accessibilityLabel(segment.title)
        } else if let count = segment.count {
            Text("\(segment.title) \(count, format: .number)")
                .accessibilityLabel(Text("\(segment.title), \(count, format: .number)"))
        } else {
            segment.title
        }
    }
}
