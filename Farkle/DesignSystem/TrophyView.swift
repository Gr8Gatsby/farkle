import SwiftUI

/// Hand-drawn gold trophy with a crimson ribbon banner across the cup.
/// Ported faithfully from the design SVG (viewBox 220×264), so the
/// height is automatically `size * 1.2`.
struct TrophyView: View {
    var size: CGFloat = 220
    var ribbon: String = "WINNER"

    var body: some View {
        Canvas { ctx, c in
            let s = c.width / 220.0
            let cupShade = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.953, green: 0.847, blue: 0.588), location: 0),
                    .init(color: Color(red: 0.910, green: 0.784, blue: 0.471), location: 0.35),
                    .init(color: Color(red: 0.722, green: 0.541, blue: 0.243), location: 0.70),
                    .init(color: Color(red: 0.478, green: 0.353, blue: 0.149), location: 1)
                ]),
                startPoint: CGPoint(x: 110 * s, y: 60 * s),
                endPoint: CGPoint(x: 110 * s, y: 178 * s)
            )
            let cupDeep = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.478, green: 0.353, blue: 0.149), location: 0),
                    .init(color: Color(red: 0.239, green: 0.173, blue: 0.071), location: 1)
                ]),
                startPoint: CGPoint(x: 110 * s, y: 174 * s),
                endPoint: CGPoint(x: 110 * s, y: 244 * s)
            )
            let ribbonShade = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.784, green: 0.286, blue: 0.173), location: 0),
                    .init(color: Color(red: 0.541, green: 0.184, blue: 0.082), location: 1)
                ]),
                startPoint: CGPoint(x: 0, y: 130 * s),
                endPoint: CGPoint(x: 0, y: 168 * s)
            )
            let gold = Color(red: 0.953, green: 0.847, blue: 0.588)

            // Drop shadow under base
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 3 * s))
                let rect = CGRect(x: (110 - 56) * s, y: 246 * s,
                                  width: 112 * s, height: 12 * s)
                l.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.30)))
            }

            // Base + plinth
            ctx.fill(
                Path(roundedRect: CGRect(x: 62 * s, y: 220 * s, width: 96 * s, height: 24 * s),
                     cornerRadius: 3 * s),
                with: cupDeep)
            ctx.fill(
                Path(roundedRect: CGRect(x: 62 * s, y: 220 * s, width: 96 * s, height: 6 * s),
                     cornerRadius: 2 * s),
                with: .color(.white.opacity(0.18)))
            ctx.fill(Path(CGRect(x: 80 * s, y: 200 * s, width: 60 * s, height: 22 * s)),
                     with: cupDeep)
            ctx.fill(Path(CGRect(x: 78 * s, y: 198 * s, width: 64 * s, height: 6 * s)),
                     with: cupShade)

            // Stem
            var stem = Path()
            stem.move(to: CGPoint(x: 96 * s, y: 198 * s))
            stem.addLine(to: CGPoint(x: 92 * s, y: 174 * s))
            stem.addLine(to: CGPoint(x: 128 * s, y: 174 * s))
            stem.addLine(to: CGPoint(x: 124 * s, y: 198 * s))
            stem.closeSubpath()
            ctx.fill(stem, with: cupDeep)

            // Handles (strokes)
            var leftHandle = Path()
            leftHandle.move(to: CGPoint(x: 52 * s, y: 96 * s))
            leftHandle.addQuadCurve(to: CGPoint(x: 22 * s, y: 132 * s),
                                    control: CGPoint(x: 22 * s, y: 100 * s))
            leftHandle.addQuadCurve(to: CGPoint(x: 60 * s, y: 158 * s),
                                    control: CGPoint(x: 22 * s, y: 156 * s))
            ctx.stroke(leftHandle, with: cupDeep,
                       style: StrokeStyle(lineWidth: 10 * s, lineCap: .round))

            var rightHandle = Path()
            rightHandle.move(to: CGPoint(x: 168 * s, y: 96 * s))
            rightHandle.addQuadCurve(to: CGPoint(x: 198 * s, y: 132 * s),
                                     control: CGPoint(x: 198 * s, y: 100 * s))
            rightHandle.addQuadCurve(to: CGPoint(x: 160 * s, y: 158 * s),
                                     control: CGPoint(x: 198 * s, y: 156 * s))
            ctx.stroke(rightHandle, with: cupDeep,
                       style: StrokeStyle(lineWidth: 10 * s, lineCap: .round))

            // Cup body
            var cup = Path()
            cup.move(to: CGPoint(x: 50 * s, y: 70 * s))
            cup.addQuadCurve(to: CGPoint(x: 60 * s, y: 60 * s),
                             control: CGPoint(x: 50 * s, y: 60 * s))
            cup.addLine(to: CGPoint(x: 160 * s, y: 60 * s))
            cup.addQuadCurve(to: CGPoint(x: 170 * s, y: 70 * s),
                             control: CGPoint(x: 170 * s, y: 60 * s))
            cup.addLine(to: CGPoint(x: 162 * s, y: 168 * s))
            cup.addQuadCurve(to: CGPoint(x: 150 * s, y: 178 * s),
                             control: CGPoint(x: 160 * s, y: 178 * s))
            cup.addLine(to: CGPoint(x: 70 * s, y: 178 * s))
            cup.addQuadCurve(to: CGPoint(x: 58 * s, y: 168 * s),
                             control: CGPoint(x: 60 * s, y: 178 * s))
            cup.closeSubpath()
            ctx.fill(cup, with: cupShade)
            ctx.stroke(cup,
                       with: .color(Color(red: 0.478, green: 0.353, blue: 0.149).opacity(0.6)),
                       lineWidth: 1.5 * s)

            // Cup interior shadows
            ctx.fill(Path(ellipseIn: CGRect(x: (110 - 58) * s, y: 58 * s,
                                            width: 116 * s, height: 20 * s)),
                     with: .color(Color(red: 0.239, green: 0.173, blue: 0.071)))
            ctx.fill(Path(ellipseIn: CGRect(x: (110 - 58) * s, y: 60 * s,
                                            width: 116 * s, height: 16 * s)),
                     with: .color(Color(red: 0.478, green: 0.353, blue: 0.149)))
            ctx.stroke(Path(ellipseIn: CGRect(x: (110 - 58) * s, y: 58 * s,
                                              width: 116 * s, height: 12 * s)),
                       with: .color(gold),
                       lineWidth: 2 * s)

            // Vertical shine
            let shine = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: Color.white.opacity(0.36), location: 0),
                    .init(color: Color.white.opacity(0), location: 1)
                ]),
                startPoint: CGPoint(x: 62 * s, y: 0),
                endPoint: CGPoint(x: 84 * s, y: 0)
            )
            ctx.fill(
                Path(roundedRect: CGRect(x: 62 * s, y: 72 * s, width: 22 * s, height: 102 * s),
                     cornerRadius: 6 * s),
                with: shine)

            // Ribbon banner
            var ribbonPath = Path()
            ribbonPath.move(to: CGPoint(x: 44 * s, y: 130 * s))
            ribbonPath.addLine(to: CGPoint(x: 176 * s, y: 130 * s))
            ribbonPath.addLine(to: CGPoint(x: 168 * s, y: 158 * s))
            ribbonPath.addLine(to: CGPoint(x: 176 * s, y: 168 * s))
            ribbonPath.addLine(to: CGPoint(x: 44 * s, y: 168 * s))
            ribbonPath.addLine(to: CGPoint(x: 52 * s, y: 158 * s))
            ribbonPath.closeSubpath()
            ctx.fill(ribbonPath, with: ribbonShade)

            // Ribbon folds (darker)
            let fold = GraphicsContext.Shading.color(Color(red: 0.431, green: 0.122, blue: 0.055))
            var foldL = Path()
            foldL.move(to: CGPoint(x: 44 * s, y: 130 * s))
            foldL.addLine(to: CGPoint(x: 50 * s, y: 134 * s))
            foldL.addLine(to: CGPoint(x: 50 * s, y: 168 * s))
            foldL.addLine(to: CGPoint(x: 44 * s, y: 168 * s))
            foldL.closeSubpath()
            ctx.fill(foldL, with: fold)
            var foldR = Path()
            foldR.move(to: CGPoint(x: 176 * s, y: 130 * s))
            foldR.addLine(to: CGPoint(x: 170 * s, y: 134 * s))
            foldR.addLine(to: CGPoint(x: 170 * s, y: 168 * s))
            foldR.addLine(to: CGPoint(x: 176 * s, y: 168 * s))
            foldR.closeSubpath()
            ctx.fill(foldR, with: fold)

            // Ribbon text
            let ribbonText = Text(ribbon)
                .font(.custom("InstrumentSerif-Italic", size: 22 * s))
                .foregroundColor(Color(red: 0.984, green: 0.898, blue: 0.867))
                .tracking(2 * s)
            ctx.draw(ribbonText, at: CGPoint(x: 110 * s, y: 149 * s), anchor: .center)

            // Sparkles (small dots + four-point stars)
            let goldShade = GraphicsContext.Shading.color(gold)
            ctx.fill(Path(ellipseIn: CGRect(x: 33 * s, y: 77 * s, width: 6 * s, height: 6 * s)),
                     with: goldShade)
            ctx.fill(Path(ellipseIn: CGRect(x: 187.5 * s, y: 57.5 * s, width: 5 * s, height: 5 * s)),
                     with: goldShade)
            ctx.fill(Path(ellipseIn: CGRect(x: 182 * s, y: 198 * s, width: 4 * s, height: 4 * s)),
                     with: goldShade)
            var star1 = Path()
            star1.move(to: CGPoint(x: 30 * s, y: 30 * s))
            star1.addLine(to: CGPoint(x: 32 * s, y: 36 * s))
            star1.addLine(to: CGPoint(x: 38 * s, y: 38 * s))
            star1.addLine(to: CGPoint(x: 32 * s, y: 40 * s))
            star1.addLine(to: CGPoint(x: 30 * s, y: 46 * s))
            star1.addLine(to: CGPoint(x: 28 * s, y: 40 * s))
            star1.addLine(to: CGPoint(x: 22 * s, y: 38 * s))
            star1.addLine(to: CGPoint(x: 28 * s, y: 36 * s))
            star1.closeSubpath()
            ctx.fill(star1, with: .color(gold.opacity(0.85)))
            var star2 = Path()
            star2.move(to: CGPoint(x: 200 * s, y: 110 * s))
            star2.addLine(to: CGPoint(x: 201 * s, y: 114 * s))
            star2.addLine(to: CGPoint(x: 205 * s, y: 115 * s))
            star2.addLine(to: CGPoint(x: 201 * s, y: 116 * s))
            star2.addLine(to: CGPoint(x: 200 * s, y: 120 * s))
            star2.addLine(to: CGPoint(x: 199 * s, y: 116 * s))
            star2.addLine(to: CGPoint(x: 195 * s, y: 115 * s))
            star2.addLine(to: CGPoint(x: 199 * s, y: 114 * s))
            star2.closeSubpath()
            ctx.fill(star2, with: .color(gold.opacity(0.80)))
        }
        .frame(width: size, height: size * 1.2)
    }
}
