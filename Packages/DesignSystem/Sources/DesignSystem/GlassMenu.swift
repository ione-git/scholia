import SwiftUI

private let menuInset: CGFloat = 4
private let rowHeight: CGFloat = 46
private let rowPadding: CGFloat = 14

extension View {
    public func glassMenu<Menu: View>(
        isPresented: Binding<Bool>, alignment: Alignment, @ViewBuilder menu: () -> Menu
    ) -> some View {
        overlay(alignment: alignment) {
            ZStack(alignment: alignment) {
                if isPresented.wrappedValue {
                    Color.clear
                        .contentShape(.rect)
                        .ignoresSafeArea()
                        .onTapGesture { isPresented.wrappedValue = false }
                        .accessibilityHidden(true)
                    menu()
                        .accessibilityElement(children: .contain)
                        .accessibilityAddTraits(.isModal)
                        .accessibilityAction(.escape) { isPresented.wrappedValue = false }
                        .transition(
                            .scale(scale: GlassMenuMotion.scale, anchor: GlassMenuMotion.anchor(alignment))
                                .combined(with: .opacity))
                }
            }
            .animation(.snappy, value: isPresented.wrappedValue)
        }
    }
}

private enum GlassMenuMotion {
    static let scale: CGFloat = 0.8

    static func anchor(_ alignment: Alignment) -> UnitPoint {
        let x: CGFloat =
            alignment.horizontal == .leading ? 0 : alignment.horizontal == .trailing ? 1 : UnitPoint.center.x
        let y: CGFloat = alignment.vertical == .top ? 0 : alignment.vertical == .bottom ? 1 : UnitPoint.center.y
        return UnitPoint(x: x, y: y)
    }
}

public struct GlassMenu<Content: View>: View {
    private static var width: CGFloat { 240 }
    private static var separatorInset: CGFloat { 10 }

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    row
                    if row.id != rows.last?.id {
                        Rectangle()
                            .fill(.hairline)
                            .frame(height: .hairlineW)
                            .padding(.horizontal, Self.separatorInset)
                    }
                }
            }
        }
        .padding(menuInset)
        .frame(width: Self.width)
        .glassEffect(.regular.tint(.surfaceGlassStrong), in: RoundedRectangle(cornerRadius: .radiusXl))
    }
}

public struct GlassMenuItem: View {
    private static let iconSize: CGFloat = 20
    private static let iconStroke: CGFloat = 2

    let title: Text
    let icon: Icon
    let action: () -> Void

    public init(_ title: Text, icon: Icon, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: .space3) {
                title
                    .textStyle(.body)
                    .lineLimit(1)
                Spacer(minLength: 0)
                IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
            }
            .foregroundStyle(.ink)
            .padding(.horizontal, rowPadding)
            .frame(height: rowHeight)
        }
        .buttonStyle(MenuRowStyle())
    }
}

public struct GlassMenuOption: View {
    private static let checkSize: CGFloat = 18
    private static let checkStroke: CGFloat = 2.6

    let title: Text
    let isSelected: Bool
    let action: () -> Void

    public init(_ title: Text, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: .space3) {
                title
                    .textStyle(.body)
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isSelected {
                    IconView(icon: .check, size: Self.checkSize, stroke: Self.checkStroke)
                        .foregroundStyle(.accent)
                }
            }
            .padding(.horizontal, rowPadding)
            .frame(height: rowHeight)
        }
        .buttonStyle(MenuRowStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct GlassMenuHeader: View {
    private static let height: CGFloat = 40
    private static let padding: CGFloat = 10
    private static let spacing: CGFloat = 6
    private static let iconSize: CGFloat = 16
    private static let iconStroke: CGFloat = 2.4

    let title: Text
    let action: () -> Void

    public init(_ title: Text, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Self.spacing) {
                IconView(icon: .back, size: Self.iconSize, stroke: Self.iconStroke)
                title
                    .textStyle(TextStyle.subhead.weighted(TextStyle.title3.weight))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.inkMuted)
            .padding(.horizontal, Self.padding)
            .frame(height: Self.height)
        }
        .buttonStyle(MenuRowStyle())
    }
}

private struct MenuRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: .radiusXl - menuInset)
        configuration.label
            .contentShape(shape)
            .background {
                if configuration.isPressed {
                    shape.fill(.controlFill)
                }
            }
    }
}
