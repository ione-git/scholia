#if DEBUG
    import DesignSystem
    import SwiftUI

    struct TokenGallery: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .space6) {
                    section("Colours") {
                        ForEach(ColorToken.all) { token in
                            HStack(spacing: .space3) {
                                ColorSwatch(token: token, scheme: .light)
                                ColorSwatch(token: token, scheme: .dark)
                                Text(token.name).textStyle(.body)
                            }
                        }
                    }
                    section("Text styles") {
                        ForEach(TextStyle.all) { style in
                            Text(style.name)
                                .textStyle(style)
                                .accessibilityIdentifier("tokenGallery.textStyle.\(style.name)")
                                .accessibilityValue(Text(style.uiFont.fontName))
                        }
                    }
                    section("Spacing") {
                        ForEach(NumberToken.spacing) { token in
                            numberRow(token, element: "spacing") {
                                Rectangle().fill(.ink).frame(width: token.value, height: .space2)
                            }
                        }
                    }
                    section("Radius") {
                        ForEach(NumberToken.radius) { token in
                            numberRow(token, element: "radius") {
                                RoundedRectangle(cornerRadius: token.value)
                                    .fill(.surfaceCard)
                                    .stroke(.controlBorder, lineWidth: .hairlineW)
                                    .frame(width: .controlH, height: .controlH)
                            }
                        }
                    }
                    section("Shadows") {
                        ForEach(ShadowToken.all) { token in
                            HStack(spacing: .space4) {
                                RoundedRectangle(cornerRadius: .radiusMd)
                                    .fill(.track)
                                    .frame(width: .controlH, height: .controlH)
                                    .shadow(token, in: RoundedRectangle(cornerRadius: .radiusMd))
                                Text(token.name).textStyle(.body)
                            }
                            .padding(.vertical, .space2)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("tokenGallery.shadow.\(token.name)")
                        }
                    }
                    section("Effects") {
                        ForEach(NumberToken.effects) { token in
                            numberRow(token, element: "effect") {}
                        }
                    }
                    section("Reader themes") {
                        ForEach(ReaderTheme.allCases, id: \.self) { theme in
                            RoundedRectangle(cornerRadius: .radiusMd)
                                .fill(theme.page)
                                .stroke(.controlBorder, lineWidth: .hairlineW)
                                .frame(height: .controlH)
                                .overlay {
                                    Text(theme.rawValue).textStyle(.readingBody).foregroundStyle(theme.text)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("tokenGallery.readerTheme.\(theme.rawValue)")
                        }
                    }
                }
                .padding(.horizontal, .space5)
                .padding(.bottom, .space10)
                .foregroundStyle(.ink)
            }
            .accessibilityIdentifier("tokenGallery.scrollView")
            .background(.surface)
            .navigationTitle("Token Gallery")
        }

        private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
            VStack(alignment: .leading, spacing: .space3) {
                Text(title).textStyle(.section)
                content()
            }
        }

        private func numberRow(_ token: NumberToken, element: String, @ViewBuilder sample: () -> some View)
            -> some View
        {
            HStack(spacing: .space3) {
                Text(token.name).textStyle(.body)
                Spacer()
                Text(token.value, format: .number).textStyle(.body).foregroundStyle(.inkMuted)
                sample()
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("tokenGallery.\(element).\(token.name)")
        }
    }

    private struct ColorSwatch: View {
        let token: ColorToken
        let scheme: ColorScheme

        var body: some View {
            RoundedRectangle(cornerRadius: .radiusMd)
                .fill(token.color)
                .stroke(.controlBorder, lineWidth: .hairlineW)
                .background(.surface, in: RoundedRectangle(cornerRadius: .radiusMd))
                .frame(width: .controlH, height: .controlH)
                .environment(\.colorScheme, scheme)
                .accessibilityElement()
                .accessibilityLabel(scheme == .light ? Text("Light") : Text("Dark"))
                .accessibilityIdentifier("tokenGallery.\(element).\(token.name)")
        }

        private var element: String { scheme == .light ? "lightSwatch" : "darkSwatch" }
    }
#endif
