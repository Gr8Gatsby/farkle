import SwiftUI

struct StandingsLadder: View {
    let game: Game
    var session: FarkleNetSession? = nil
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(text: "Standings")
                Spacer()
                if let onEdit {
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Edit")
                                .font(.ui(11, weight: .semibold))
                                .tracking(0.6)
                        }
                        .foregroundStyle(Color.ink3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit players")
                }
            }
            .padding(.horizontal, 4)

            let ordered = game.orderedPlayers
            let ranks = scoreRanks(players: ordered)
            VStack(spacing: 0) {
                ForEach(Array(ordered.enumerated()), id: \.element.id) { idx, player in
                    let rank = ranks[player.id] ?? (idx + 1)
                    playerRow(player: player, rank: rank)
                    if idx < ordered.count - 1 {
                        Rectangle().fill(Color.walnut.opacity(0.08)).frame(height: 0.5)
                    }
                }
            }
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Unified player row

    private func playerRow(player: Player, rank: Int) -> some View {
        let isActive = player.id == game.activePlayer?.id
        let pct = min(1.0, Double(player.bankedScore) / Double(max(1, game.targetScore)))

        let avatarSize: CGFloat = isActive ? 44 : 28
        let vPad: CGFloat = isActive ? 14 : 10
        let nameColor = isActive ? Color.walnutInk : Color.ink
        let scoreColor = isActive ? Color.walnutInk : Color.ink
        let bgColor = isActive ? Color.walnut : Color.clear
        let barFill = isActive ? Color.gold : Color.walnut

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    AvatarView(name: player.name,
                               colorIndex: player.avatarIndex,
                               size: avatarSize,
                               active: isActive,
                               photoData: session?.photoData(for: player.id))
                        .opacity(isActive ? 0 : 1)
                    Image(systemName: "dice.fill")
                        .font(.system(size: avatarSize * 0.55, weight: .semibold))
                        .foregroundStyle(Color.gold)
                        .frame(width: avatarSize, height: avatarSize)
                        .opacity(isActive ? 1 : 0)
                }
                .frame(width: avatarSize, height: avatarSize)

                Text(player.name)
                    .font(isActive ? .display(26, italic: true) : .ui(15, weight: .medium))
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer()

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.walnut.opacity(0.12)).frame(width: 50, height: 3)
                    Capsule()
                        .fill(barFill)
                        .frame(width: 50 * pct, height: 3)
                }

                MonoScoreText(value: player.bankedScore,
                              size: isActive ? 24 : 15,
                              weight: .bold,
                              color: scoreColor)
                    .frame(minWidth: 40, alignment: .trailing)

                rankBadge(rank, active: isActive)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, vPad)
            .background(bgColor)

            if isActive {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.gold)
                        .frame(width: proxy.size.width * pct, height: 3)
                }
                .frame(height: 3)
                .background(Color.walnut.opacity(0.15))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: isActive)
    }

    // MARK: - Helpers

    private func scoreRanks(players: [Player]) -> [UUID: Int] {
        let sorted = players.sorted { $0.bankedScore > $1.bankedScore }
        var ranks: [UUID: Int] = [:]
        for (i, p) in sorted.enumerated() {
            if i > 0, sorted[i - 1].bankedScore == p.bankedScore {
                ranks[p.id] = ranks[sorted[i - 1].id]!
            } else {
                ranks[p.id] = i + 1
            }
        }
        return ranks
    }

    private func rankBadge(_ rank: Int, active: Bool) -> some View {
        Text(ordinal(rank))
            .font(.mono(10, weight: .bold))
            .foregroundStyle(active
                             ? Color.walnutInk.opacity(0.8)
                             : (rank == 1 ? Color.walnut : Color.ink3))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(active
                        ? Color.walnutInk.opacity(0.12)
                        : (rank == 1 ? Color.gold.opacity(0.25) : Color.walnut.opacity(0.08)))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}
