import SwiftUI

extension View {
    public func modalSheet<Content: View>(
        isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        scrim(isShown: isPresented.wrappedValue) { isPresented.wrappedValue = false }
            .sheet(isPresented: isPresented) {
                content()
                    .presentationBackground(.surface)
                    .presentationCornerRadius(.radiusSheet)
                    .scrimmedSheetChrome()
            }
    }

    public func cardSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>, onDismiss: @escaping () -> Void, @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        scrim(isShown: item.wrappedValue != nil) { item.wrappedValue = nil }
            .sheet(item: item, onDismiss: onDismiss) { item in
                FittedSheet { content(item) }
            }
    }

    fileprivate func scrim(isShown: Bool, dismiss: @escaping () -> Void) -> some View {
        accessibilityHidden(isShown)
            .overlay {
                ZStack {
                    if isShown {
                        Color.scrim
                            .ignoresSafeArea()
                            .onTapGesture(perform: dismiss)
                    }
                }
                .animation(.default, value: isShown)
            }
    }

    fileprivate func scrimmedSheetChrome() -> some View {
        sheetGrabber()
            .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }

    public func glassSheetStyle() -> some View {
        presentationCornerRadius(.radiusSheet)
            .sheetGrabber()
            .presentationBackgroundInteraction(.enabled)
    }

    fileprivate func sheetGrabber() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) { SheetGrabber() }
            .presentationDragIndicator(.hidden)
    }

    public func popoverStyle() -> some View {
        presentationCompactAdaptation(.popover)
            .presentationCornerRadius(.radiusXl)
    }
}

private struct FittedSheet<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var height: CGFloat?

    var body: some View {
        ScrollView {
            content
                .padding(.top, SheetGrabber.clearance)
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { newHeight in
                    height = newHeight
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents(height.map { [.height($0)] } ?? [.medium])
        .presentationCornerRadius(.radiusSheet)
        .scrimmedSheetChrome()
    }
}

private struct SheetGrabber: View {
    private static let width: CGFloat = 36
    private static let height: CGFloat = 5

    static let clearance: CGFloat = .space2 + height + .space4

    var body: some View {
        Capsule()
            .fill(.track)
            .frame(width: Self.width, height: Self.height)
            .padding(.top, .space2)
    }
}

public struct SheetHeader<Leading: View, Trailing: View>: View {
    let title: Text
    let leading: Leading
    let trailing: Trailing

    public init(_ title: Text, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        ZStack {
            title
                .textStyle(.title3)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                leading
                Spacer(minLength: 0)
                trailing
            }
        }
        .frame(minHeight: .controlH)
    }
}

public struct SheetButtonStyle: PrimitiveButtonStyle {
    public enum Role: Sendable {
        case cancel
        case done
        case back
    }

    private static let backIconSize: CGFloat = 20
    private static let backIconStroke: CGFloat = 2.2
    private static let backIconSpacing: CGFloat = 2

    let role: Role

    public init(_ role: Role) {
        self.role = role
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            HStack(spacing: Self.backIconSpacing) {
                if role == .back {
                    IconView(icon: .back, size: Self.backIconSize, stroke: Self.backIconStroke)
                }
                configuration.label
                    .textStyle(role == .done ? .title3 : TextStyle.title3.weighted(TextStyle.body.weight))
            }
            .foregroundStyle(.accent)
            .frame(minHeight: .controlH)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

extension PrimitiveButtonStyle where Self == SheetButtonStyle {
    public static var sheetCancel: SheetButtonStyle { SheetButtonStyle(.cancel) }
    public static var sheetDone: SheetButtonStyle { SheetButtonStyle(.done) }
    public static var sheetBack: SheetButtonStyle { SheetButtonStyle(.back) }
}
