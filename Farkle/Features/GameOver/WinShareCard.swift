import SwiftUI

/// A 1080×1080 felt-themed brag card used as the source for ImageRenderer.
/// Designed to feel cohesive with the Game Over screen but standalone (no
/// touch targets, no system chrome, generous type).
struct WinShareCard: View {
    let game: Game

    private var winner: Player? {
        game.orderedPlayers.first(where: { $0.id == game.winnerPlayerID })
            ?? game.orderedPlayers.max(by: { $0.bankedScore < $1.bankedScore })
    }

    private var standings: [Player] {
        game.orderedPlayers.sorted { $0.bankedScore > $1.bankedScore }
    }

    var body: some View {
        ZStack {
            Color.felt
            LinearGradient(
                colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.30)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 36) {
                VStack(spacing: 14) {
                    Text("FARKLE")
                        .font(.ui(28, weight: .bold))
                        .tracking(8)
                        .foregroundStyle(Color.gold)
                    Text(game.name)
                        .font(.display(40))
                        .foregroundStyle(Color.paper)
                }

                if let winner {
                    VStack(spacing: 22) {
                        AvatarView(name: winner.name, colorIndex: winner.avatarIndex, size: 220, active: true)
                            .shadow(color: Color.gold.opacity(0.6), radius: 30, x: 0, y: 0)
                        (
                            Text("\(winner.name)\n").font(.display(120, italic: true))
                                .foregroundStyle(Color.paper) +
                            Text("wins.").font(.display(120))
                                .foregroundStyle(Color.gold2)
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(-30)

                        Text(winner.bankedScore.formatted())
                            .font(.mono(72, weight: .bold))
                            .foregroundStyle(Color.gold2)
                    }
                }

                VStack(spacing: 14) {
                    Text("FINAL STANDINGS")
                        .font(.ui(22, weight: .bold))
                        .tracking(5)
                        .foregroundStyle(Color.paper.opacity(0.55))

                    VStack(spacing: 0) {
                        ForEach(Array(standings.enumerated()), id: \.element.id) { idx, p in
                            HStack(spacing: 18) {
                                Text("\(idx + 1)")
                                    .font(.display(46, italic: true))
                                    .foregroundStyle(idx == 0 ? Color.gold2 : Color.paper.opacity(0.55))
                                    .frame(width: 56, alignment: .leading)
                                AvatarView(name: p.name, colorIndex: p.avatarIndex, size: 60)
                                Text(p.name)
                                    .font(.ui(38, weight: .medium))
                                    .foregroundStyle(Color.paper)
                                Spacer()
                                Text(p.bankedScore.formatted())
                                    .font(.mono(38, weight: .bold))
                                    .foregroundStyle(idx == 0 ? Color.gold2 : Color.paper)
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            if idx < standings.count - 1 {
                                Rectangle().fill(Color.paper.opacity(0.10))
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.paper.opacity(0.10), lineWidth: 1)
                    )
                    .padding(.horizontal, 32)
                }

                Spacer(minLength: 0)

                Text(dateLine)
                    .font(.ui(22))
                    .foregroundStyle(Color.paper.opacity(0.55))
                    .padding(.bottom, 24)
            }
            .padding(.top, 64)
            .padding(.horizontal, 56)
        }
        .frame(width: 1080, height: 1080)
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: game.endedAt ?? Date())
    }
}

/// Render a Game's win card to a UIImage suitable for the share sheet.
@MainActor
enum WinImageRenderer {
    static func image(for game: Game) -> UIImage? {
        let renderer = ImageRenderer(content: WinShareCard(game: game))
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
