import SwiftUI

extension View {
    public func modalSheet<Content: View>(
        isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        accessibilityHidden(isPresented.wrappedValue)
            .overlay {
                ZStack {
                    if isPresented.wrappedValue {
                        Color.scrim
                            .ignoresSafeArea()
                            .onTapGesture { isPresented.wrappedValue = false }
                    }
                }
                .animation(.default, value: isPresented.wrappedValue)
            }
            .sheet(isPresented: isPresented) {
                content()
                    .presentationBackground(.surface)
                    .presentationCornerRadius(.radiusSheet)
                    .sheetGrabber()
                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
            }
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

private struct SheetGrabber: View {
    private static let width: CGFloat = 36
    private static let height: CGFloat = 5

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
    }

    let role: Role

    public init(_ role: Role) {
        self.role = role
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .textStyle(role == .done ? .title3 : TextStyle.title3.weighted(TextStyle.body.weight))
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
}
