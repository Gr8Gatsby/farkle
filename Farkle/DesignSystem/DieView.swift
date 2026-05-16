import SwiftUI

struct DieView: View {
    var value: Int
    var size: CGFloat = 48
    var scoring: Bool = false
    var held: Bool = false
    var dim: Bool = false

    var body: some View {
        let pips = Self.pips[value] ?? []
        let pipSize = max(4, size * 0.13)
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.996, green: 0.984, blue: 0.953),
                            Color.bone,
                            Color(red: 0.941, green: 0.910, blue: 0.839)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.10), radius: 1, x: 0, y: 1)

            ForEach(Array(pips.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.290, green: 0.227, blue: 0.157), Color.bonePip],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: pipSize
                        )
                    )
                    .frame(width: pipSize, height: pipSize)
                    .offset(
                        x: (CGFloat(point.0 - 1) * 0.35 + 0.175 - 0.5) * size,
                        y: (CGFloat(point.1 - 1) * 0.35 + 0.175 - 0.5) * size
                    )
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(scoring ? Color.gold : (held ? Color.walnut : Color.clear),
                        lineWidth: 2.5)
                .padding(-2)
        )
        .offset(y: held ? -3 : 0)
        .opacity(dim ? 0.5 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: held)
    }

    /// (col, row) pip positions on a 3x3 grid.
    static let pips: [Int: [(Int, Int)]] = [
        1: [(2,2)],
        2: [(1,1),(3,3)],
        3: [(1,1),(2,2),(3,3)],
        4: [(1,1),(1,3),(3,1),(3,3)],
        5: [(1,1),(1,3),(2,2),(3,1),(3,3)],
        6: [(1,1),(1,2),(1,3),(3,1),(3,2),(3,3)],
    ]
}
