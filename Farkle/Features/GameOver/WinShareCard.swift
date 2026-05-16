import SwiftUI

/// A 1080×1080 felt-themed brag card used as the source for ImageRenderer.
/// Renders from a host-side `Game` or a joiner-side `GameSnapshot`.
struct WinShareCard: View {
    let gameName: String
    let endedAt: Date?
    let players: [WinPlayer]
    let winnerID: UUID?
    let photoFor: (UUID) -> Data?

    struct WinPlayer: Identifiable {
        let id: UUID
        let name: String
        let avatarIndex: Int
        let bankedScore: Int
    }

    init(game: Game, photoFor: @escaping (UUID) -> Data?) {
        self.gameName = game.name
        self.endedAt = game.endedAt
        self.players = game.orderedPlayers.map {
            WinPlayer(id: $0.id, name: $0.name,
                      avatarIndex: $0.avatarIndex,
                      bankedScore: $0.bankedScore)
        }
        self.winnerID = game.winnerPlayerID
        self.photoFor = photoFor
    }

    init(snapshot: GameSnapshot) {
        self.gameName = snapshot.gameName
        self.endedAt = snapshot.endedAt
        self.players = snapshot.players.map {
            WinPlayer(id: $0.id, name: $0.name,
                      avatarIndex: $0.avatarIndex,
                      bankedScore: $0.bankedScore)
        }
        self.winnerID = snapshot.winnerPlayerID
        self.photoFor = { id in snapshot.photoData(for: id) }
    }

    private var winner: WinPlayer? {
        players.first(where: { $0.id == winnerID })
            ?? players.max(by: { $0.bankedScore < $1.bankedScore })
    }

    private var standings: [WinPlayer] {
        players.sorted { $0.bankedScore > $1.bankedScore }
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
                    Text(gameName)
                        .font(.display(40))
                        .foregroundStyle(Color.paper)
                }

                if let winner {
                    VStack(spacing: 22) {
                        winnerCrest(winner: winner)
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
                                AvatarView(name: p.name,
                                           colorIndex: p.avatarIndex,
                                           size: 60,
                                           photoData: photoFor(p.id))
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

    /// Winner avatar / monogram with a laurel + trophy crest behind it.
    private func winnerCrest(winner: WinPlayer) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gold.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .frame(width: 460, height: 460)

            Circle()
                .stroke(Color.gold.opacity(0.5), lineWidth: 2)
                .frame(width: 320, height: 320)
            Circle()
                .stroke(Color.gold.opacity(0.25), lineWidth: 1)
                .frame(width: 360, height: 360)

            AvatarView(name: winner.name,
                       colorIndex: winner.avatarIndex,
                       size: 240,
                       active: true,
                       photoData: photoFor(winner.id))
                .shadow(color: Color.gold.opacity(0.7), radius: 30, x: 0, y: 0)

            Image(systemName: "trophy.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(Color.walnut)
                .padding(20)
                .background(Color.gold)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.paper, lineWidth: 4))
                .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 6)
                .offset(x: 90, y: 100)
        }
        .frame(width: 460, height: 460)
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: endedAt ?? Date())
    }
}

/// Render a Game's win card to a UIImage suitable for the share sheet.
@MainActor
enum WinImageRenderer {
    static func image(for game: Game, session: FarkleNetSession? = nil) -> UIImage? {
        let card = WinShareCard(game: game) { id in session?.photoData(for: id) }
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.0
        return renderer.uiImage
    }

    static func image(for snapshot: GameSnapshot) -> UIImage? {
        let renderer = ImageRenderer(content: WinShareCard(snapshot: snapshot))
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
