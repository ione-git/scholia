#if DEBUG
    import DesignSystem
    import SwiftUI

    struct GalleryPage<Content: View>: View {
        let title: Text
        let identifier: String
        let colorScheme: ColorScheme?
        @ViewBuilder let content: Content
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .space6) {
                    header
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .space5)
                .padding(.bottom, .space10)
            }
            .accessibilityIdentifier(identifier)
            .background(.surface)
            .foregroundStyle(.ink)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(colorScheme)
        }

        private var header: some View {
            ZStack {
                title
                    .textStyle(.section)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Button("Back") { dismiss() }
                        .buttonStyle(.sheetBack)
                        .accessibilityIdentifier("gallery.back")
                    Spacer(minLength: 0)
                }
            }
            .frame(height: .controlH)
        }
    }
#endif
