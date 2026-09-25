import SwiftUI

public struct SearchField: View {
    private static let height: CGFloat = 40
    private static let iconSize: CGFloat = 18
    private static let iconStroke: CGFloat = 2

    let text: Binding<String>
    let prompt: Text
    let label: Text

    public init(text: Binding<String>, prompt: Text, label: Text) {
        self.text = text
        self.prompt = prompt
        self.label = label
    }

    public var body: some View {
        HStack(spacing: .space2) {
            IconView(icon: .search, size: Self.iconSize, stroke: Self.iconStroke)
                .foregroundStyle(.inkMuted)
            TextField(text: text, prompt: prompt.foregroundStyle(Color.inkMuted)) { label }
                .textStyle(.body)
                .foregroundStyle(.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .accessibilityAddTraits(.isSearchField)
        }
        .padding(.horizontal, .space3)
        .frame(height: Self.height)
        .background(.controlFill, in: RoundedRectangle(cornerRadius: .radiusMd))
    }
}
