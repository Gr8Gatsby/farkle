import SwiftUI

/// Tabular number that animates between values when the underlying Int changes.
/// Uses `withAnimation` on the displayed value so the digits "tick" up or down.
struct AnimatedScoreText: View, Animatable {
    var value: Double
    var size: CGFloat = 56
    var color: Color = .paper

    init(value: Int, size: CGFloat = 56, color: Color = .paper) {
        self.value = Double(value)
        self.size = size
        self.color = color
    }

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(Int(value.rounded()), format: .number)
            .font(.mono(size, weight: .bold))
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
    }
}
