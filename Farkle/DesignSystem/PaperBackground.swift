import SwiftUI

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Color.paper
            Canvas { ctx, size in
                let dots: [(x: Double, y: Double, r: Double, op: Double)] = [
                    (0.17, 0.23, 1.0, 0.06),
                    (0.73, 0.71, 1.0, 0.05),
                    (0.41, 0.89, 1.0, 0.05),
                    (0.87, 0.13, 1.4, 0.04)
                ]
                let walnut = Color.walnut
                let cell: Double = 200
                let cols = Int(ceil(size.width / cell)) + 1
                let rows = Int(ceil(size.height / cell)) + 1
                for i in 0..<rows {
                    for j in 0..<cols {
                        let baseX = Double(j) * cell
                        let baseY = Double(i) * cell
                        for d in dots {
                            let x = baseX + d.x * cell
                            let y = baseY + d.y * cell
                            let rect = CGRect(x: x - d.r, y: y - d.r, width: d.r * 2, height: d.r * 2)
                            ctx.fill(Path(ellipseIn: rect), with: .color(walnut.opacity(d.op)))
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct PaperBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            PaperBackground()
            content
        }
    }
}

extension View {
    func paperBackground() -> some View { modifier(PaperBackgroundModifier()) }
}
