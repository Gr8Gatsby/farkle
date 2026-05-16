import SwiftUI

struct BankConfirmSheet: View {
    let game: Game
    let hotDice: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        guard let player = game.activePlayer else {
            return AnyView(EmptyView())
        }
        let was = player.bankedScore
        let now = was + game.pendingTurnScore
        let willTriggerFinal = game.finalRoundTriggeredByPlayerID == nil && now >= game.targetScore
        let nextPlayerName = nextPlayer()?.name

        return AnyView(
            VStack(spacing: 0) {
                Capsule().fill(Color.walnut.opacity(0.25)).frame(width: 40, height: 4)
                    .padding(.top, 8)
                Text("CONFIRM TURN")
                    .font(.ui(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.ink3)
                    .padding(.top, 12)
                (
                    Text(willTriggerFinal ? "\(player.name) " : "Bank ")
                        .font(.display(24))
                        .foregroundStyle(Color.ink) +
                    Text(willTriggerFinal ? "hits the target" : "+\(game.pendingTurnScore)")
                        .font(.display(24, italic: true))
                        .foregroundStyle(Color.walnut) +
                    Text(willTriggerFinal ? "." : " for \(player.name)?")
                        .font(.display(24))
                        .foregroundStyle(Color.ink)
                )
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 24)

                deltaCard(player: player, was: was, now: now)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                Text("You can undo this from the Recent actions list.")
                    .font(.ui(11))
                    .foregroundStyle(Color.ink3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                HStack(spacing: 8) {
                    Button("Keep rolling") { onCancel() }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.clear)
                        .foregroundStyle(Color.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                        )
                        .font(.ui(14, weight: .semibold))

                    Button {
                        onConfirm()
                    } label: {
                        Text(willTriggerFinal
                             ? "Bank & start final round →"
                             : "Bank & pass to \(nextPlayerName ?? "next") →")
                    }
                    .buttonStyle(WalnutButtonStyle(size: .regular, fullWidth: true))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
        )
    }

    private func deltaCard(player: Player, was: Int, now: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(name: player.name, colorIndex: player.avatarIndex, size: 36, active: true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name)
                        .font(.ui(13, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text("was \(was.formatted())")
                        .font(.mono(10))
                        .foregroundStyle(Color.ink3)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text(was.formatted())
                        .font(.mono(14))
                        .foregroundStyle(Color.ink3)
                        .strikethrough()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.ink3)
                    Text(now.formatted())
                        .font(.mono(18, weight: .bold))
                        .foregroundStyle(Color.walnut)
                }
            }

            // Progress bar
            GeometryReader { proxy in
                let totalW = proxy.size.width
                let wasW = totalW * CGFloat(min(1.0, Double(was) / Double(game.targetScore)))
                let nowW = totalW * CGFloat(min(1.0, Double(now) / Double(game.targetScore)))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.walnut.opacity(0.1)).frame(height: 6)
                    Capsule().fill(Color.walnut.opacity(0.4)).frame(width: wasW, height: 6)
                    Capsule().fill(Color.gold)
                        .frame(width: max(0, nowW - wasW), height: 6)
                        .offset(x: wasW)
                }
            }
            .frame(height: 6)

            HStack {
                Text("0").font(.mono(10)).foregroundStyle(Color.ink3)
                Spacer()
                Text(game.targetScore.formatted()).font(.mono(10)).foregroundStyle(Color.ink3)
            }
        }
        .padding(14)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
        )
    }

    private func nextPlayer() -> Player? {
        let ordered = game.orderedPlayers
        guard !ordered.isEmpty else { return nil }
        let next = (game.activePlayerIndex + 1) % ordered.count
        return ordered[next]
    }
}

struct BustConfirmSheet: View {
    let game: Game
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.walnut.opacity(0.25)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text("FARKLE")
                .font(.ui(11, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.crimson)
                .padding(.top, 14)
            Text("Bust \(game.activePlayer?.name ?? "this turn")?")
                .font(.display(26, italic: true))
                .foregroundStyle(Color.ink)
                .padding(.top, 4)
            Text("The pending \(game.pendingTurnScore.formatted()) will be discarded. You can undo this from Recent actions.")
                .font(.ui(13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink2)
                .padding(.horizontal, 28)
                .padding(.top, 8)

            HStack(spacing: 8) {
                Button("Keep rolling") { onCancel() }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.clear)
                    .foregroundStyle(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                    )
                    .font(.ui(14, weight: .semibold))
                Button {
                    onConfirm()
                } label: {
                    Text("Bust turn →")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.crimson)
                        .foregroundStyle(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .font(.ui(14, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }
}
