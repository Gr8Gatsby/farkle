import SwiftUI

struct ConfettiView: View {
    var pieceCount: Int = 64
    @State private var pieces: [Piece] = []

    struct Piece: Identifiable {
        let id = UUID()
        let xRatio: Double
        let delay: Double
        let duration: Double
        let color: Color
        let shape: Int
        let size: Double
        let spin: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for p in pieces {
                    let t = (now.truncatingRemainder(dividingBy: 4)) - p.delay
                    guard t >= 0 else { continue }
                    let progress = min(1, t / p.duration)
                    let x = p.xRatio * size.width
                    let y = progress * (size.height + 40) - 20
                    let alpha: Double
                    if progress < 0.1 { alpha = progress * 10 }
                    else if progress > 0.9 { alpha = (1 - progress) * 10 }
                    else { alpha = 1 }
                    let rect = CGRect(x: x - p.size / 2, y: y - p.size / 2, width: p.size, height: p.size)
                    var transform = ctx
                    transform.translateBy(x: rect.midX, y: rect.midY)
                    transform.rotate(by: .degrees(progress * p.spin))
                    let local = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size)
                    let path: Path
                    switch p.shape {
                    case 0: path = Path(ellipseIn: local)
                    case 1: path = Path(roundedRect: local, cornerRadius: 1)
                    default: path = Path(local)
                    }
                    transform.fill(path, with: .color(p.color.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { generate() }
    }

    private func generate() {
        let palette: [Color] = [.crimson, .gold, .felt, .walnut, .gold2, .crimson.opacity(0.85)]
        pieces = (0..<pieceCount).map { i in
            Piece(
                xRatio: Double.random(in: 0...1),
                delay: Double.random(in: 0...0.6),
                duration: Double.random(in: 1.6...2.8),
                color: palette[i % palette.count],
                shape: i % 3,
                size: Double.random(in: 6...12),
                spin: Double.random(in: 360...720)
            )
        }
    }
}
