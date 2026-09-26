import SwiftUI

public struct StepSlider: View {
    private static let railHeight: CGFloat = 4
    private static let thumbSize: CGFloat = 22
    private static let thumbEdgeOffset: CGFloat = 1
    private static let thumbEdgeBlur: CGFloat = 4

    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: Text
    let onEditingChanged: (Bool) -> Void

    @State private var isEditing = false

    public init(
        value: Binding<Int>, in range: ClosedRange<Int>, label: Text, onEditingChanged: @escaping (Bool) -> Void
    ) {
        _value = value
        self.range = range
        self.label = label
        self.onEditingChanged = onEditingChanged
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let position = width * fraction
            ZStack(alignment: .leading) {
                Capsule().fill(.track).frame(height: Self.railHeight)
                Capsule().fill(.accent).frame(width: position, height: Self.railHeight)
                Circle()
                    .fill(.surfaceCard)
                    .shadow(color: .controlBorder, radius: Self.thumbEdgeBlur / 2, y: Self.thumbEdgeOffset)
                    .frame(width: Self.thumbSize, height: Self.thumbSize)
                    .offset(x: position - Self.thumbSize / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isEditing {
                            isEditing = true
                            onEditingChanged(true)
                        }
                        move(to: drag.location.x, in: width)
                    }
                    .onEnded { drag in
                        move(to: drag.location.x, in: width)
                        isEditing = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: .controlH)
        .accessibilityRepresentation {
            Slider(
                value: continuousValue, in: Double(range.lowerBound)...Double(range.upperBound), step: 1,
                label: { label }, onEditingChanged: onEditingChanged)
        }
    }

    private var fraction: CGFloat {
        CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
    }

    private var continuousValue: Binding<Double> {
        Binding {
            Double(value)
        } set: { newValue in
            value = Int(newValue.rounded())
        }
    }

    private func move(to x: CGFloat, in width: CGFloat) {
        let steps = CGFloat(range.upperBound - range.lowerBound)
        let step = range.lowerBound + Int((min(max(x / width, 0), 1) * steps).rounded())
        if step != value {
            value = step
        }
    }
}
