import SwiftUI

public struct TranslationDetails {
    let hint: Text
    let action: () -> Void

    public init(hint: Text, action: @escaping () -> Void) {
        self.hint = hint
        self.action = action
    }
}

extension View {
    func accessibilityOpensDetails(_ details: TranslationDetails?) -> some View {
        modifier(DetailsAccessibility(details: details))
    }
}

private struct DetailsAccessibility: ViewModifier {
    let details: TranslationDetails?

    func body(content: Content) -> some View {
        if let details {
            content
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(details.hint)
                .accessibilityAction { details.action() }
        } else {
            content
        }
    }
}
