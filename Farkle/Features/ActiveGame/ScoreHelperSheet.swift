import SwiftUI

struct ScoreHelperSheet: View {
    let rules: HouseRules
    var onAdd: (ScoreBreakdown) -> Void
    var onCancel: () -> Void

    @State private var dice: [Int] = []

    private var breakdown: ScoreBreakdown {
        ScoreHelperEngine(rules: rules).score(dice: dice)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.walnut.opacity(0.25)).frame(width: 40, height: 4)
                .padding(.top, 8)
            HStack {
                (
                    Text("Score ").font(.display(28)).foregroundStyle(Color.ink) +
                    Text("helper").font(.display(28, italic: true)).foregroundStyle(Color.walnut)
                )
                Spacer()
                Button("Clear") {
                    dice.removeAll()
                }
                .font(.ui(13, weight: .semibold))
                .foregroundStyle(Color.ink3)
                .opacity(dice.isEmpty ? 0 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text("Tap the dice you rolled — we'll add them up.")
                .font(.ui(12))
                .foregroundStyle(Color.ink3)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            // Slots
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    if i < dice.count {
                        Button {
                            dice.remove(at: i)
                        } label: {
                            DieView(value: dice[i], size: 42, scoring: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.walnut.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .frame(width: 42, height: 42)
                    }
                }
            }
            .padding(14)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.top, 14)

            SectionLabel(text: "Add a die")
                .padding(.horizontal, 20)
                .padding(.top, 14)

            HStack(spacing: 6) {
                ForEach(1...6, id: \.self) { v in
                    Button {
                        if dice.count < 6 { dice.append(v) }
                    } label: {
                        DieView(value: v, size: 36)
                            .padding(6)
                            .background(Color.paperSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.walnut.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .disabled(dice.count >= 6)
                    .opacity(dice.count >= 6 ? 0.4 : 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Combo breakdown
            VStack(spacing: 6) {
                ForEach(breakdown.combos) { combo in
                    HStack {
                        Text(combo.label)
                            .font(.ui(13))
                            .foregroundStyle(Color.ink)
                        Spacer()
                        Text("+\(combo.points.formatted())")
                            .font(.mono(13, weight: .semibold))
                            .foregroundStyle(Color.ink)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.paperSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
                    )
                }
                if !breakdown.leftover.isEmpty {
                    HStack {
                        Text("Non-scoring")
                            .font(.ui(12))
                            .foregroundStyle(Color.ink3)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(Array(breakdown.leftover.enumerated()), id: \.offset) { _, v in
                                DieView(value: v, size: 16, dim: true)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                HStack {
                    Text("This roll")
                        .font(.display(18, italic: true))
                        .foregroundStyle(Color.walnutInk)
                    if breakdown.usesAllDice {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                            Text("Hot dice")
                                .font(.ui(10, weight: .bold))
                                .tracking(1)
                        }
                        .foregroundStyle(Color.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gold.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    Spacer()
                    Text("+\(breakdown.total.formatted())")
                        .font(.mono(18, weight: .bold))
                        .foregroundStyle(Color.walnutInk)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.walnut)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            HStack(spacing: 10) {
                Button("Cancel") { onCancel() }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .foregroundStyle(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                    )
                    .font(.ui(14, weight: .semibold))

                Button {
                    onAdd(breakdown)
                } label: {
                    Text("Add to turn")
                }
                .buttonStyle(WalnutButtonStyle(size: .regular, fullWidth: true))
                .disabled(breakdown.total == 0)
                .opacity(breakdown.total == 0 ? 0.5 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)

            Spacer(minLength: 0)
        }
    }
}
