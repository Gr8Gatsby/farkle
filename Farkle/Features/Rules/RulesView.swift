import SwiftUI

struct RulesView: View {
    private let rows: [(name: String, dice: [Int], pts: String)] = [
        ("Single 1", [1], "100"),
        ("Single 5", [5], "50"),
        ("Three 1s", [1,1,1], "1,000"),
        ("Three 2s", [2,2,2], "200"),
        ("Three 3s", [3,3,3], "300"),
        ("Three 4s", [4,4,4], "400"),
        ("Three 5s", [5,5,5], "500"),
        ("Three 6s", [6,6,6], "600"),
        ("Four of a kind", [4,4,4,4], "2×"),
        ("Five of a kind", [3,3,3,3,3], "4×"),
        ("Six of a kind", [6,6,6,6,6,6], "8×"),
        ("Straight 1–6", [1,2,3,4,5,6], "1,500"),
        ("Three pairs", [2,2,4,4,6,6], "1,500")
    ]

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    howItWorks.padding(.horizontal, 16)
                    SectionLabel(text: "Score chart").padding(.horizontal, 24).padding(.top, 16)
                    chart.padding(.horizontal, 16)
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CHEAT SHEET")
                .font(.ui(11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Color.ink3)
            (
                Text("How to ").font(.display(42)).foregroundStyle(Color.ink) +
                Text("score").font(.display(42, italic: true)).foregroundStyle(Color.walnut)
            )
        }
        .padding(.horizontal, 24)
    }

    private var howItWorks: some View {
        PaperCard {
            VStack(spacing: 12) {
                step(num: 1, title: "Roll all six dice.", body: "Set aside any scoring dice. Re-roll the rest, or bank.")
                HandRule()
                step(num: 2, title: "No score? Farkle.", body: "You lose your turn's points. Pass to the next player.")
                HandRule()
                step(num: 3, title: "First to 10,000 wins.", body: "Everyone else gets one last roll to catch up.")
            }
        }
    }

    private func step(num: Int, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(num)")
                .font(.display(36, italic: true))
                .foregroundStyle(Color.walnut)
                .frame(width: 36, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ui(13, weight: .semibold)).foregroundStyle(Color.ink)
                Text(body).font(.ui(13)).foregroundStyle(Color.ink2).lineSpacing(2)
            }
        }
    }

    private var chart: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        ForEach(Array(row.dice.enumerated()), id: \.offset) { _, v in
                            DieView(value: v, size: 16)
                        }
                    }
                    .frame(width: 110, alignment: .leading)
                    Text(row.name).font(.ui(13)).foregroundStyle(Color.ink)
                    Spacer()
                    Text(row.pts).font(.mono(13, weight: .bold)).foregroundStyle(Color.walnut)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if idx < rows.count - 1 {
                    Rectangle().fill(Color.walnut.opacity(0.10)).frame(height: 0.5).padding(.leading, 14)
                }
            }
        }
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
        )
    }
}
