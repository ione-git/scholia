#if DEBUG
    import DesignSystem
    import SwiftUI

    struct GalleryPage<Content: View>: View {
        let identifier: String
        let colorScheme: ColorScheme?
        @ViewBuilder let content: Content

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .space6) { content }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .space5)
                    .padding(.bottom, .space10)
            }
            .accessibilityIdentifier(identifier)
            .background(.surface)
            .foregroundStyle(.ink)
            .preferredColorScheme(colorScheme)
        }
    }
#endif
