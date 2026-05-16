import SwiftUI

/// Mono number that animates from 0 to `value` once on appear, easing out cubic.
struct CountUpScore: View {
    let value: Int
    var duration: Double = 1.4
    var size: CGFloat = 36
    var color: Color = .walnut

    @State private var animated: Double = 0

    var body: some View {
        AnimatableNumber(value: animated, size: size, color: color)
            .onAppear {
                animated = 0
                withAnimation(.easeOut(duration: duration)) {
                    animated = Double(value)
                }
            }
    }
}

private struct AnimatableNumber: View, Animatable {
    var value: Double
    var size: CGFloat
    var color: Color

    nonisolated var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(Int(value.rounded()), format: .number)
            .font(.mono(size, weight: .bold))
            .foregroundStyle(color)
            .monospacedDigit()
    }
}
