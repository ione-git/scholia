import DesignSystem
import ReaderEngine
import SwiftData
import SwiftUI

struct ReaderSettingsSheet: View {
    let theme: ReaderTheme
    let pick: (ReaderTheme) -> Void

    @Environment(Settings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @State private var height: CGFloat?
    @State private var bottomInset: CGFloat?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space4) {
                themes
                fonts
                size
                pageTurn
                spacingAndRotation
            }
            .padding(.horizontal, .space5)
            .padding(.top, .space8)
            .padding(.bottom, .space5)
            .onGeometryChange(for: CGFloat.self) {
                $0.size.height
            } action: {
                height = $0
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .ignoresSafeArea(.container, edges: .bottom)
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.bottom
        } action: {
            bottomInset = $0
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("readerSettings.sheet")
        .presentationDetents(detents)
        .glassSheetStyle()
    }

    private var detents: Set<PresentationDetent> {
        guard let height, let bottomInset else {
            return [.medium]
        }
        return [.height(height - bottomInset)]
    }

    private var themes: some View {
        HStack(spacing: 0) {
            ForEach(ReaderTheme.allCases, id: \.self) { option in
                if option != ReaderTheme.allCases.first {
                    Spacer(minLength: 0)
                }
                ThemeSwatch(
                    option, title: Text(option.title), label: Text(option.label), isSelected: option == theme
                ) {
                    pick(option)
                }
                .accessibilityIdentifier("readerSettings.theme.\(option.rawValue)")
            }
        }
        .padding(.horizontal, .space1)
    }

    private var fonts: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .space2) {
                ForEach(ReaderFont.allCases, id: \.self) { font in
                    FontChip(font.title, font: font.chipFont, isSelected: font == settings.readerFont) {
                        settings.update(\.readerFont, to: font, in: modelContext)
                    }
                    .accessibilityIdentifier("readerSettings.font.\(font.rawValue)")
                }
            }
            .padding(.horizontal, .space5)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -.space5)
    }

    private var size: some View {
        HStack(spacing: .space3) {
            TextSizeButton(.smaller, label: Text("Smaller text")) {
                settings.update(\.textSizeStep, to: settings.textSizeStep - 1, in: modelContext)
            }
            .disabled(settings.textSizeStep <= ReaderStyle.sizeSteps.lowerBound)
            .accessibilityIdentifier("readerSettings.smaller")
            Slider(value: sizeStep, in: sizeRange, step: 1) {
                Text("Text size")
            } onEditingChanged: { isEditing in
                if !isEditing {
                    modelContext.saveLogged()
                }
            }
            .tint(.accent)
            .accessibilityValue(Text("\(settings.textSizeStep) of \(ReaderStyle.sizeSteps.upperBound)"))
            .accessibilityIdentifier("readerSettings.size")
            TextSizeButton(.larger, label: Text("Larger text")) {
                settings.update(\.textSizeStep, to: settings.textSizeStep + 1, in: modelContext)
            }
            .disabled(settings.textSizeStep >= ReaderStyle.sizeSteps.upperBound)
            .accessibilityIdentifier("readerSettings.larger")
        }
    }

    private var pageTurn: some View {
        VStack(alignment: .leading, spacing: .space2) {
            Text("Page turn")
                .textStyle(.labelCaps)
                .foregroundStyle(.inkMuted)
                .padding(.leading, .space1)
                .accessibilityAddTraits(.isHeader)
            SegmentedControl(
                selection: binding(\.pageTurn), size: .regular,
                segments: [
                    .init(.slide, title: Text("Slide"), count: nil, identifier: "readerSettings.pageTurn.slide"),
                    .init(.fade, title: Text("Fade"), count: nil, identifier: "readerSettings.pageTurn.fade"),
                    .init(.scroll, title: Text("Scroll"), count: nil, identifier: "readerSettings.pageTurn.scroll"),
                ])
        }
    }

    private var spacingAndRotation: some View {
        HStack(spacing: .space3) {
            SegmentedControl(
                selection: binding(\.lineSpacing), size: .regular,
                segments: [
                    .init(
                        .tight, icon: .lineSpacingTight, label: Text("Tight line spacing"),
                        identifier: "readerSettings.lineSpacing.tight"),
                    .init(
                        .normal, icon: .lineSpacingNormal, label: Text("Normal line spacing"),
                        identifier: "readerSettings.lineSpacing.normal"),
                    .init(
                        .loose, icon: .lineSpacingLoose, label: Text("Loose line spacing"),
                        identifier: "readerSettings.lineSpacing.loose"),
                ])
            if UIDevice.current.userInterfaceIdiom == .phone {
                Toggle(isOn: binding(\.locksRotation)) {
                    Text("Lock rotation")
                }
                .toggleStyle(.icon(.rotationLock))
                .accessibilityIdentifier("readerSettings.lockRotation")
            }
        }
    }

    private var sizeRange: ClosedRange<Double> {
        Double(ReaderStyle.sizeSteps.lowerBound)...Double(ReaderStyle.sizeSteps.upperBound)
    }

    private var sizeStep: Binding<Double> {
        Binding {
            Double(settings.textSizeStep)
        } set: { value in
            let step = Int(value.rounded())
            if step != settings.textSizeStep {
                settings.textSizeStep = step
            }
        }
    }

    private func binding<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<Settings, Value>) -> Binding<Value> {
        Binding {
            settings[keyPath: keyPath]
        } set: { value in
            settings.update(keyPath, to: value, in: modelContext)
        }
    }
}
