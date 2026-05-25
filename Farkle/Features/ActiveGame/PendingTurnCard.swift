import SwiftUI

struct PendingTurnCard: View {
    @Bindable var game: Game
    var onQuickAdd: (Int) -> Void
    var onClear: () -> Void
    var onFarkle: () -> Void

    private let chips = [50, 100, 200, 300, 350, 500, 1000, 1500]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS TURN · NOT BANKED YET")
                    .font(.ui(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.ink3)
                Spacer()
                HStack(spacing: 8) {
                    Text("\(game.pendingRollCount) roll\(game.pendingRollCount == 1 ? "" : "s")")
                        .font(.mono(10))
                        .foregroundStyle(Color.ink3)
                    if game.pendingTurnScore > 0 {
                        Button("Clear") { onClear() }
                            .font(.ui(12, weight: .semibold))
                            .foregroundStyle(Color.ink3)
                    }
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(chips, id: \.self) { v in
                    Button { onQuickAdd(v) } label: {
                        Text("\(v)")
                    }
                    .buttonStyle(ChipButtonStyle(fullWidth: true))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                BigScoreText(value: game.pendingTurnScore, size: 48, color: .ink)
                    .contentTransition(.numericText(value: Double(game.pendingTurnScore)))
                    .animation(.easeOut(duration: 0.35), value: game.pendingTurnScore)
                Text("pending")
                    .font(.ui(13))
                    .foregroundStyle(Color.ink3)
                Spacer()
                farkleButton
            }
        }
        .padding(14)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.ink.opacity(0.10), radius: 12, x: 0, y: 4)
        .shadow(color: Color.ink.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var farkleButton: some View {
        Button {
            onFarkle()
        } label: {
            Text("FARKLE")
                .font(.ui(16, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.paper)
                .padding(.horizontal, 24)
                .frame(height: 52)
                .background(Color.crimson)
                .clipShape(Capsule())
                .shadow(color: Color.crimson.opacity(0.40), radius: 0, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Farkle — bust this turn")
    }
}

/// Minimal flow layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > width {
                totalHeight += rowHeight + spacing
                maxRowWidth = max(maxRowWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        maxRowWidth = max(maxRowWidth, rowWidth - spacing)
        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
