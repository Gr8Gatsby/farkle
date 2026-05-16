import SwiftUI

struct BigScoreText: View {
    var value: Int
    var size: CGFloat = 56
    var color: Color = .ink

    var body: some View {
        Text(value, format: .number)
            .font(.display(size))
            .foregroundStyle(color)
            .monospacedDigit()
            .kerning(-1)
    }
}

struct MonoScoreText: View {
    var value: Int
    var size: CGFloat = 14
    var weight: Font.Weight = .bold
    var color: Color = .ink

    var body: some View {
        Text(value, format: .number)
            .font(.mono(size, weight: weight))
            .foregroundStyle(color)
    }
}
