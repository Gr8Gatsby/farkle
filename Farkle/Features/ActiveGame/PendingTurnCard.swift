import SwiftUI

struct PendingTurnCard: View {
    @Bindable var game: Game
    @Binding var markHotDice: Bool
    var onQuickAdd: (Int) -> Void
    var onClear: () -> Void
    var onOpenHelper: () -> Void
    var onOpenKeypad: () -> Void

    private let chips = [50, 100, 150, 200, 300, 500, 1000]

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
            FlowLayout(spacing: 6) {
                ForEach(chips, id: \.self) { v in
                    Button { onQuickAdd(v) } label: {
                        Text("+\(v)")
                    }
                    .buttonStyle(ChipButtonStyle())
                }
                Button {
                    onOpenKeypad()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.forwardslash.minus")
                            .font(.system(size: 12, weight: .semibold))
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
                Toggle(isOn: $markHotDice) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                        Text("Hot dice")
                            .font(.ui(11, weight: .semibold))
                    }
                    .foregroundStyle(markHotDice ? Color.gold : Color.ink3)
                }
                .toggleStyle(HotDiceToggleStyle())
            }
        }
        .padding(14)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.walnut.opacity(0.30), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }
}

struct HotDiceToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 4) {
                configuration.label
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(configuration.isOn ? Color.gold.opacity(0.18) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(configuration.isOn ? Color.gold : Color.ink3.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
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
