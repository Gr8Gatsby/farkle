import SwiftUI

struct StandingsLadder: View {
    let game: Game
    var session: FarkleNetSession? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Standings")
                .padding(.horizontal, 4)

            let sorted = game.orderedPlayers.sorted { $0.bankedScore > $1.bankedScore }
            VStack(spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, player in
                    row(rank: idx + 1, player: player)
                    if idx < sorted.count - 1 {
                        Rectangle().fill(Color.walnut.opacity(0.08)).frame(height: 0.5).padding(.leading, 14)
                    }
                }
            }
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
        }
    }

    private func row(rank: Int, player: Player) -> some View {
        let isActive = player.id == game.activePlayer?.id
        let pct = min(1.0, Double(player.bankedScore) / Double(max(1, game.targetScore)))
        return HStack(spacing: 10) {
            Text("\(rank)")
                .font(.mono(11, weight: .bold))
                .foregroundStyle(Color.ink3.opacity(0.7))
                .frame(width: 14)
            AvatarView(name: player.name,
                       colorIndex: player.avatarIndex,
                       size: 22,
                       photoData: session?.photoData(for: player.id))
            HStack(spacing: 6) {
                Text(player.name)
                    .font(.ui(13, weight: .medium))
                    .foregroundStyle(Color.ink)
                if isActive {
                    Text("ROLLING")
                        .font(.mono(8, weight: .bold))
                        .tracking(0.6)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gold)
                        .foregroundStyle(Color.walnut)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
            }
            Spacer()
            // mini progress bar
            ZStack(alignment: .leading) {
                Capsule().fill(Color.walnut.opacity(0.12)).frame(width: 50, height: 3)
                Capsule()
                    .fill(isActive ? Color.gold : Color.walnut)
                    .frame(width: 50 * pct, height: 3)
            }
            MonoScoreText(value: player.bankedScore, size: 13, weight: .bold, color: .ink)
                .frame(minWidth: 56, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
