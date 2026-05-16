import SwiftUI

struct GameOverView: View {
    @Bindable var game: Game
    var onUndo: () -> Void
    var onExit: () -> Void
    var onRematch: () -> Void

    private var winner: Player? {
        game.players.first(where: { $0.id == game.winnerPlayerID })
            ?? game.orderedPlayers.max(by: { $0.bankedScore < $1.bankedScore })
    }

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()
            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            ConfettiView()

            VStack {
                VStack(spacing: 8) {
                    Text(game.name.uppercased())
                        .font(.ui(11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color.paper.opacity(0.65))
                    if let winner {
                        (
                            Text("\(winner.name)\n").font(.display(60, italic: true))
                                .foregroundStyle(Color.paper) +
                            Text("wins.").font(.display(60))
                                .foregroundStyle(Color.gold2)
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(-12)
                    }
                }
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 14) {
                    if let winner {
                        ZStack(alignment: .bottom) {
                            AvatarView(name: winner.name, colorIndex: winner.avatarIndex, size: 92, active: true)
                            Text(winner.bankedScore.formatted())
                                .font(.mono(12, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.walnut)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gold)
                                .clipShape(Capsule())
                                .offset(y: 8)
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                    }
                    standings
                    Button(action: onUndo) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Wait — that's wrong. Undo last bank.")
                                .font(.ui(13, weight: .semibold))
                        }
                        .foregroundStyle(Color.paper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.paper.opacity(0.20), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Button("Recap") { onExit() }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.10))
                            .foregroundStyle(Color.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.paper.opacity(0.15), lineWidth: 0.5)
                            )
                            .font(.ui(13, weight: .semibold))
                        Button { onRematch() } label: {
                            Text("Rematch")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.gold)
                                .foregroundStyle(Color.walnut)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .font(.ui(13, weight: .bold))
                                .shadow(color: Color.black.opacity(0.4), radius: 0, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private var standings: some View {
        VStack(spacing: 0) {
            let sorted = game.orderedPlayers.sorted { $0.bankedScore > $1.bankedScore }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, p in
                HStack(spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.display(20, italic: true))
                        .foregroundStyle(idx == 0 ? Color.gold2 : Color.paper.opacity(0.5))
                        .frame(width: 24)
                    AvatarView(name: p.name, colorIndex: p.avatarIndex, size: 28)
                    Text(p.name)
                        .font(.ui(14, weight: .medium))
                        .foregroundStyle(Color.paper)
                    Spacer()
                    Text(p.bankedScore.formatted())
                        .font(.mono(14, weight: .semibold))
                        .foregroundStyle(idx == 0 ? Color.gold2 : Color.paper)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                if idx < sorted.count - 1 {
                    Rectangle().fill(Color.paper.opacity(0.08)).frame(height: 0.5)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.paper.opacity(0.06), lineWidth: 0.5)
        )
    }
}
