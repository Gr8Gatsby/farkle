import SwiftUI

struct HandRule: View {
    var color: Color = .ink2
    var opacity: Double = 0.3

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let w = proxy.size.width
                path.move(to: CGPoint(x: 2, y: 2))
                path.addQuadCurve(to: CGPoint(x: w / 2, y: 2),
                                  control: CGPoint(x: w * 0.25, y: 0.5))
                path.addQuadCurve(to: CGPoint(x: w - 2, y: 2),
                                  control: CGPoint(x: w * 0.75, y: 3.5))
            }
            .stroke(color.opacity(opacity), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        .frame(height: 4)
    }
}

struct SectionLabel: View {
    let text: String
    var color: Color = .ink3

    var body: some View {
        Text(text.uppercased())
            .font(.ui(11, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(color)
    }
}
