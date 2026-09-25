import SwiftUI

public struct ListTextField: View {
    private static let labelWidth: CGFloat = 84
    private static let height = ListRow<EmptyView>.Height.regular.value

    let label: Text
    let text: Binding<String>

    public init(_ label: Text, text: Binding<String>) {
        self.label = label
        self.text = text
    }

    public var body: some View {
        HStack(spacing: .space3) {
            label
                .textStyle(TextStyle.callout.weighted(TextStyle.body.weight))
                .foregroundStyle(.inkMuted)
                .frame(width: Self.labelWidth, alignment: .leading)
                .accessibilityHidden(true)
            TextField(text: text, prompt: Text(String())) { label }
                .textStyle(.body)
                .foregroundStyle(.ink)
                .autocorrectionDisabled()
        }
        .frame(minHeight: Self.height)
    }
}
