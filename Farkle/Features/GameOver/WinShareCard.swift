import SwiftUI

/// 1080×1920 portrait "story" card used as the source for ImageRenderer.
/// Renders from a host-side `Game` or a joiner-side `GameSnapshot`.
/// Paper-themed: cream background, walnut + gold accents, trophy crest.
struct WinShareCard: View {
    let gameName: String
    let endedAt: Date?
    let players: [WinPlayer]
    let winnerID: UUID?
    let rounds: Int
    let durationLabel: String
    let hotDiceCount: Int
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
        self.rounds = max(1, game.orderedActions
            .filter { $0.kind == .bank || $0.kind == .bust }.count
            / max(1, game.orderedPlayers.count))
        let winnerPlayer = game.orderedPlayers.first(where: { $0.id == game.winnerPlayerID })
        self.hotDiceCount = winnerPlayer?.hotDiceCount ?? 0
        if let end = game.endedAt {
            let s = end.timeIntervalSince(game.createdAt)
            let h = Int(s) / 3600
            let m = (Int(s) % 3600) / 60
            self.durationLabel = h > 0 ? "\(h)h \(m)m" : "\(m)m"
        } else {
            self.durationLabel = "—"
        }
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
        let bankBust = snapshot.recentActions.filter { $0.kind == .bank || $0.kind == .bust }.count
        self.rounds = max(1, bankBust / max(1, snapshot.players.count))
        self.hotDiceCount = snapshot.players.first(where: { $0.id == snapshot.winnerPlayerID })?.hotDiceCount ?? 0
        self.durationLabel = "—"
        self.photoFor = { id in snapshot.photoData(for: id) }
    }

    private var winner: WinPlayer? {
        players.first(where: { $0.id == winnerID })
            ?? players.max(by: { $0.bankedScore < $1.bankedScore })
    }

    private var defeatedNames: [WinPlayer] {
        players.filter { $0.id != winner?.id }
            .sorted { $0.bankedScore > $1.bankedScore }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return "· \(f.string(from: endedAt ?? Date()).uppercased()) ·"
    }

    var body: some View {
        ZStack {
            paperBackground

            // Decorative top + bottom walnut strokes (gradient bars)
            VStack {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.walnut, .clear],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 8)
                Spacer()
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.walnut, .clear],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 8)
            }

            // Warm halo behind the trophy
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.gold.opacity(0.30), location: 0),
                    .init(color: .clear, location: 0.65)
                ]),
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 0, endRadius: 640
            )
            .blendMode(.multiply)

            // Corner watermarks
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gameName.uppercased())
                            .font(.mono(20, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Color.walnut.opacity(0.45))
                        Text(dateLine)
                            .font(.mono(20))
                            .tracking(3)
                            .foregroundStyle(Color.walnut.opacity(0.45))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("FARKLE")
                            .font(.mono(20, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Color.walnut.opacity(0.45))
                        Text("· FREE FOREVER ·")
                            .font(.mono(20))
                            .tracking(3)
                            .foregroundStyle(Color.walnut.opacity(0.45))
                    }
                }
                .padding(.horizontal, 64)
                .padding(.top, 80)
                Spacer()
            }

            // Main composition
            VStack(spacing: 18) {
                Spacer().frame(height: 110)
                Text("THE WINNER IS")
                    .font(.ui(28, weight: .bold))
                    .tracking(8)
                    .foregroundStyle(Color.ink3)

                if let winner {
                    TrophyView(size: 380, ribbon: winner.name.split(separator: " ").first.map { $0.uppercased() } ?? "WINNER")
                        .shadow(color: Color.walnut.opacity(0.20), radius: 30, x: 0, y: 12)
                        .padding(.top, -6)

                    let parts = winner.name.split(separator: " ")
                    let first = parts.first.map(String.init) ?? winner.name
                    let rest = parts.dropFirst().joined(separator: " ")
                    VStack(spacing: 2) {
                        Text(first)
                            .font(.display(150, italic: true))
                            .foregroundStyle(Color.walnut)
                        if !rest.isEmpty {
                            Text(rest)
                                .font(.display(150))
                                .foregroundStyle(Color.ink)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 48)

                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(winner.bankedScore.formatted())
                            .font(.mono(140, weight: .bold))
                            .foregroundStyle(Color.ink)
                        Text("POINTS")
                            .font(.mono(28, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(Color.ink3)
                    }
                    .padding(.top, 4)

                    // Stat pills
                    HStack(spacing: 16) {
                        statPill(value: "\(rounds)", label: "rounds")
                        if hotDiceCount > 0 {
                            statPill(value: "\(hotDiceCount)", label: hotDiceCount == 1 ? "hot dice" : "hot dice")
                        }
                        statPill(value: durationLabel, label: "duration")
                    }
                    .padding(.top, 14)

                    if !defeatedNames.isEmpty {
                        HStack(spacing: 18) {
                            Text("def.")
                                .font(.ui(28))
                                .foregroundStyle(Color.ink3)
                            ForEach(Array(defeatedNames.prefix(4).enumerated()), id: \.element.id) { idx, p in
                                HStack(spacing: 10) {
                                    AvatarView(name: p.name,
                                               colorIndex: p.avatarIndex,
                                               size: 56,
                                               photoData: photoFor(p.id))
                                    Text(p.name)
                                        .font(.ui(30, weight: .medium))
                                        .foregroundStyle(Color.ink2)
                                }
                                if idx < min(defeatedNames.count, 4) - 1 {
                                    Text("·").font(.ui(28)).foregroundStyle(Color.ink3)
                                }
                            }
                        }
                        .padding(.top, 32)
                    }
                }

                Spacer()
                Text("played on Farkle · the free one")
                    .font(.display(36, italic: true))
                    .foregroundStyle(Color.ink3.opacity(0.85))
                    .padding(.bottom, 96)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 48)
        }
        .frame(width: 1080, height: 1920)
    }

    private var paperBackground: some View {
        ZStack {
            Color.paper
            // Subtle paper grain via stacked radial pinpoints
            Canvas { ctx, size in
                let walnut = Color.walnut
                let cell: Double = 200
                let cols = Int(ceil(size.width / cell)) + 1
                let rows = Int(ceil(size.height / cell)) + 1
                let dots: [(x: Double, y: Double, r: Double, op: Double)] = [
                    (0.17, 0.23, 1.4, 0.06),
                    (0.73, 0.71, 1.4, 0.05),
                    (0.41, 0.89, 1.4, 0.05),
                    (0.87, 0.13, 2.0, 0.04)
                ]
                for i in 0..<rows {
                    for j in 0..<cols {
                        for d in dots {
                            let x = Double(j) * cell + d.x * cell
                            let y = Double(i) * cell + d.y * cell
                            let rect = CGRect(x: x - d.r, y: y - d.r, width: d.r * 2, height: d.r * 2)
                            ctx.fill(Path(ellipseIn: rect), with: .color(walnut.opacity(d.op)))
                        }
                    }
                }
            }
            .blendMode(.multiply)
        }
    }

    private func statPill(value: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(value)
                .font(.mono(34, weight: .bold))
                .foregroundStyle(Color.walnut)
            Text(label)
                .font(.mono(26))
                .tracking(1)
                .foregroundStyle(Color.ink3)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.paperSurface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.walnut.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.ink.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

/// Render the win story card to a UIImage suitable for the share sheet or Photos.
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
