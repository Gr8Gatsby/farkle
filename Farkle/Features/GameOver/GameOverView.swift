import SwiftUI

struct GameOverView: View {
    @Bindable var game: Game
    var onUndo: () -> Void
    var onExit: () -> Void
    var onRematch: () -> Void
    var session: FarkleNetSession? = nil

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var didAutoPrerender = false

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
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [Color.gold.opacity(0.35), .clear],
                                                     center: .center, startRadius: 0, endRadius: 120))
                                .frame(width: 220, height: 220)
                            AvatarView(name: winner.name,
                                       colorIndex: winner.avatarIndex,
                                       size: 110,
                                       active: true,
                                       photoData: session?.photoData(for: winner.id))
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.walnut)
                                .padding(10)
                                .background(Color.gold)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.paper, lineWidth: 2))
                                .shadow(color: Color.black.opacity(0.45), radius: 6, x: 0, y: 3)
                                .offset(x: 42, y: 42)
                            Text(winner.bankedScore.formatted())
                                .font(.mono(12, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.walnut)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gold)
                                .clipShape(Capsule())
                                .offset(y: 64)
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                        .padding(.bottom, 14)
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

                    Button {
                        share()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Share the win")
                                .font(.ui(15, weight: .bold))
                        }
                        .foregroundStyle(Color.walnut)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    HStack(spacing: 8) {
                        Button { onRematch() } label: {
                            Text("Rematch")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white.opacity(0.10))
                                .foregroundStyle(Color.paper)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.paper.opacity(0.20), lineWidth: 0.5)
                                )
                                .font(.ui(13, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        Button("Done") { onExit() }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.10))
                            .foregroundStyle(Color.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.paper.opacity(0.20), lineWidth: 0.5)
                            )
                            .font(.ui(13, weight: .semibold))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: shareItems(image: image))
            }
        }
        .onAppear {
            // Render the win image once so a preview thumbnail is available.
            if !didAutoPrerender {
                shareImage = WinImageRenderer.image(for: game, session: session)
                didAutoPrerender = true
            }
        }
    }

    @MainActor
    private func share() {
        if shareImage == nil {
            shareImage = WinImageRenderer.image(for: game, session: session)
        }
        if shareImage != nil {
            showShareSheet = true
        }
    }

    private func shareItems(image: UIImage) -> [Any] {
        var items: [Any] = [image]
        if let winner {
            items.append("\(winner.name) won our Farkle game at \(winner.bankedScore.formatted()).")
        }
        return items
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
                    AvatarView(name: p.name,
                               colorIndex: p.avatarIndex,
                               size: 28,
                               photoData: session?.photoData(for: p.id))
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
