#if DEBUG
    import DesignSystem
    import SwiftUI

    struct TokenGallery: View {
        private static let surfaceColours = colours(prefixedBy: ["surface", "glass"])
        private static let inkAndControlColours = colours(
            prefixedBy: ["ink", "on-", "accent", "track", "hairline", "control"])
        private static let highlightColours = colours(prefixedBy: ["highlight"])
        private static let otherColours = ColorToken.all.filter { token in
            [surfaceColours, inkAndControlColours, highlightColours].allSatisfy { group in
                !group.contains { $0.id == token.id }
            }
        }

        var body: some View {
            GalleryPage(title: Text("Token Gallery"), identifier: "tokenGallery.scrollView", colorScheme: nil) {
                GroupedList {
                    section(Text("Surface colours"), name: "coloursSurfaces") { colourRows(Self.surfaceColours) }
                    section(Text("Ink and control colours"), name: "coloursInkAndControls") {
                        colourRows(Self.inkAndControlColours)
                    }
                    section(Text("Highlight colours"), name: "coloursHighlights") {
                        colourRows(Self.highlightColours)
                    }
                    section(Text("Other colours"), name: "coloursOther") { colourRows(Self.otherColours) }
                    section(Text("Text styles"), name: "textStyles") {
                        ForEach(TextStyle.all) { style in
                            Text(style.name)
                                .textStyle(style)
                                .accessibilityIdentifier("tokenGallery.textStyle.\(style.name)")
                        }
                    }
                    section(Text("Spacing"), name: "spacing") {
                        ForEach(NumberToken.spacing) { token in
                            numberRow(token, element: "spacing") {
                                Rectangle().fill(.ink).frame(width: token.value, height: .space2)
                            }
                        }
                    }
                    section(Text("Radius"), name: "radius") {
                        ForEach(NumberToken.radius) { token in
                            numberRow(token, element: "radius") {
                                RoundedRectangle(cornerRadius: token.value)
                                    .fill(.surfaceCard)
                                    .stroke(.controlBorder, lineWidth: .hairlineW)
                                    .frame(width: .controlH, height: .controlH)
                            }
                        }
                    }
                    section(Text("Shadows"), name: "shadows") {
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
                    section(Text("Effects"), name: "effects") {
                        ForEach(NumberToken.effects) { token in
                            numberRow(token, element: "effect") {}
                        }
                    }
                    section(Text("Reader themes"), name: "readerThemes") {
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
            }
        }

        private static func colours(prefixedBy prefixes: [String]) -> [ColorToken] {
            ColorToken.all.filter { token in prefixes.contains { token.name.hasPrefix($0) } }
        }

        private func section(_ title: Text, name: String, @ViewBuilder content: () -> some View) -> some View {
            NavigationLink {
                GalleryPage(title: title, identifier: "tokenGallery.section.\(name)", colorScheme: nil) {
                    VStack(alignment: .leading, spacing: .space3) { content() }
                }
            } label: {
                ListRow(title, height: .regular) { ListRowChevron() }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("tokenGallery.\(name)")
        }

        private func colourRows(_ tokens: [ColorToken]) -> some View {
            ForEach(tokens) { token in
                HStack(spacing: .space3) {
                    ColorSwatch(token: token, scheme: .light)
                    ColorSwatch(token: token, scheme: .dark)
                    Text(token.name).textStyle(.body)
                }
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
