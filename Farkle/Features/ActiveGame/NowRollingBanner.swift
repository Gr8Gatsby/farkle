import SwiftUI

struct NowRollingBanner: View {
    let game: Game
    var session: FarkleNetSession? = nil

    var body: some View {
        guard let player = game.activePlayer else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack(spacing: 12) {
                AvatarView(name: player.name,
                           colorIndex: player.avatarIndex,
                           size: 48,
                           active: true,
                           photoData: session?.photoData(for: player.id))
                Text(player.name)
                    .font(.display(32, italic: true))
                    .foregroundStyle(Color.walnutInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if game.isInFinalRound, let bar = game.scoreToBeat {
                        Text("BEAT")
                            .font(.ui(9, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color.gold)
                        MonoScoreText(value: bar, size: 24, weight: .bold, color: .gold2)
                        Text("you: \(player.bankedScore.formatted())")
                            .font(.mono(10))
                            .foregroundStyle(Color.walnutInk.opacity(0.7))
                    } else {
                        MonoScoreText(value: player.bankedScore, size: 28, weight: .bold, color: .walnutInk)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.walnut)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.walnut.opacity(0.4), radius: 18, x: 0, y: 6)
            .id(player.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity))
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: player.id)
        )
    }
}
