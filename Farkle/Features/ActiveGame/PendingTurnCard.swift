import SwiftUI

struct PendingTurnCard: View {
    @Bindable var game: Game
    var onQuickAdd: (Int) -> Void
    var onClear: () -> Void
    var onOpenHelper: () -> Void
    var onOpenKeypad: () -> Void
    var onFarkle: () -> Void

    private let chips = [50, 100, 150, 200, 300, 350, 500, 1000]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS TURN · NOT BANKED YET")
                    .font(.ui(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.ink3)
                Spacer()
                Text("\(game.pendingRollCount) roll\(game.pendingRollCount == 1 ? "" : "s")")
                    .font(.mono(10))
                    .foregroundStyle(Color.ink3)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                BigScoreText(value: game.pendingTurnScore, size: 48, color: .ink)
                Text("pending")
                    .font(.ui(13))
                    .foregroundStyle(Color.ink3)
                Spacer()
                if game.pendingTurnScore > 0 {
                    Button("Clear") { onClear() }
                        .font(.ui(12, weight: .semibold))
                        .foregroundStyle(Color.ink3)
                }
            }

            // Quick-add chips
            FlowLayout(spacing: 8) {
                ForEach(chips, id: \.self) { v in
                    Button { onQuickAdd(v) } label: {
                        Text("+\(v)")
                    }
                    .buttonStyle(ChipButtonStyle())
                }
                Button {
                    onOpenKeypad()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.forwardslash.minus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Custom")
                    }
                }
                .buttonStyle(ChipButtonStyle())
            }

            HStack(spacing: 12) {
                Button {
                    onOpenHelper()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "die.face.5")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Score helper")
                            .font(.ui(13, weight: .semibold))
                    }
                    .foregroundStyle(Color.walnut)
                }
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
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("FARKLE")
                    .font(.ui(11, weight: .bold))
                    .tracking(1.0)
            }
            .foregroundStyle(Color.paper)
            .padding(.horizontal, 12)
            .frame(height: 32)
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
