import SwiftUI

/// Full-screen announcement shown the moment a player crosses the target score.
/// Names the leader, shows the bar to beat, and lists remaining players with their gap.
/// Tapping the CTA dismisses to the next player's turn.
struct FinalRoundAnnouncement: View {
    let game: Game
    var onContinue: () -> Void

    private var trigger: Player? {
        guard let id = game.finalRoundTriggeredByPlayerID else { return nil }
        return game.players.first(where: { $0.id == id })
    }

    private var remaining: [Player] { game.remainingFinalRoundPlayers }
    private var scoreToBeat: Int { trigger?.bankedScore ?? game.targetScore }
    private var nextUp: Player? { remaining.first }

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()
            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.25)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headline
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                Spacer(minLength: 16)

                triggerCard.padding(.horizontal, 16)

                Spacer(minLength: 16)

                remainingPanel.padding(.horizontal, 16)

                Spacer(minLength: 16)

                continueButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
            }
        }
    }

    private var headline: some View {
        VStack(spacing: 6) {
            Text("FINAL ROUND")
                .font(.ui(11, weight: .bold))
                .tracking(2.4)
                .foregroundStyle(Color.gold)
            (
                Text("Everyone else gets ").font(.display(28))
                    .foregroundStyle(Color.paper) +
                Text("one last roll.").font(.display(28, italic: true))
                    .foregroundStyle(Color.gold2)
            )
            .multilineTextAlignment(.center)
        }
    }

    private var triggerCard: some View {
        VStack(spacing: 12) {
            if let trigger {
                AvatarView(name: trigger.name, colorIndex: trigger.avatarIndex, size: 84, active: true)
                Text("\(trigger.name) hit the target")
                    .font(.ui(13))
                    .foregroundStyle(Color.paper.opacity(0.7))
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Score to beat:")
                    .font(.ui(12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.paper.opacity(0.7))
                Text(scoreToBeat.formatted())
                    .font(.mono(28, weight: .bold))
                    .foregroundStyle(Color.gold2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.30))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gold.opacity(0.45), lineWidth: 1)
            )
        }
    }

    private var remainingPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ONE TURN EACH")
                .font(.ui(10, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Color.paper.opacity(0.55))
            VStack(spacing: 0) {
                ForEach(Array(remaining.enumerated()), id: \.element.id) { idx, player in
                    row(player: player, isNext: idx == 0)
                    if idx < remaining.count - 1 {
                        Rectangle().fill(Color.paper.opacity(0.08)).frame(height: 0.5)
                    }
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paper.opacity(0.06), lineWidth: 0.5)
            )
        }
    }

    private func row(player: Player, isNext: Bool) -> some View {
        let needed = max(0, scoreToBeat - player.bankedScore + 1)
        return HStack(spacing: 12) {
            AvatarView(name: player.name, colorIndex: player.avatarIndex, size: 30, active: isNext)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.ui(14, weight: .semibold))
                        .foregroundStyle(Color.paper)
                    if isNext {
                        Text("UP NEXT")
                            .font(.mono(8, weight: .bold))
                            .tracking(0.8)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.gold)
                            .foregroundStyle(Color.walnut)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                }
                Text("at \(player.bankedScore.formatted()) — needs \(needed.formatted()) to win")
                    .font(.ui(11))
                    .foregroundStyle(Color.paper.opacity(0.65))
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack {
                Spacer()
                if let nextUp {
                    Text("Pass the dice to \(nextUp.name) →")
                } else {
                    Text("Continue →")
                }
                Spacer()
            }
        }
        .buttonStyle(WalnutButtonStyle(size: .large, fullWidth: true))
    }
}
