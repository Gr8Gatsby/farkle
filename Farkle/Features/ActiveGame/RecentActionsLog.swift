import SwiftUI

struct RecentActionsLog: View {
    let game: Game
    var onUndo: (UUID) -> Void

    var body: some View {
        let recent = Array(game.orderedActions.reversed().prefix(5))
        if recent.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionLabel(text: "Recent actions")
                    Spacer()
                    Text("Tap to undo")
                        .font(.ui(10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color.ink3.opacity(0.7))
                }
                .padding(.horizontal, 4)

                VStack(spacing: 4) {
                    ForEach(recent, id: \.id) { entry in
                        row(entry: entry)
                    }
                }
            }
        }
    }

    private func row(entry: ActionLogEntry) -> some View {
        let player = game.players.first(where: { $0.id == entry.playerID })
        return Button {
            onUndo(entry.id)
        } label: {
            HStack(spacing: 10) {
                AvatarView(name: player?.name ?? "?", colorIndex: player?.avatarIndex ?? 0, size: 20)
                HStack(spacing: 4) {
                    Text(player?.name ?? "—")
                        .font(.ui(12, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Group {
                        switch entry.kind {
                        case .bank:
                            HStack(spacing: 4) {
                                Text("banked")
                                Text("+\(entry.amount.formatted())")
                                    .font(.mono(12, weight: .bold))
                                    .foregroundStyle(Color.walnut)
                                if entry.hotDice {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.gold)
                                }
                            }
                        case .bust:
                            HStack(spacing: 4) {
                                Text("busted")
                                Text("(Farkle)").foregroundStyle(Color.crimson)
                            }
                        case .startFinalRound:
                            Text("triggered final round").foregroundStyle(Color.crimson)
                        case .endGame:
                            Text("won the game").foregroundStyle(Color.gold)
                        }
                    }
                    .font(.ui(12))
                    .foregroundStyle(Color.ink2)
                }
                Spacer()
                Text(timeAgo(entry.timestamp))
                    .font(.mono(10))
                    .foregroundStyle(Color.ink3.opacity(0.7))
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.ink3.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.walnut.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(player?.name ?? "Player") \(entry.kind == .bust ? "busted" : "banked \(entry.amount)")")
        .accessibilityAction(named: "Undo this action") { onUndo(entry.id) }
    }

    private func timeAgo(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
