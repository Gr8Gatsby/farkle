import SwiftUI

struct NowRollingBanner: View {
    let game: Game
    var session: FarkleNetSession? = nil
    @State private var pulse = false

    var body: some View {
        guard let player = game.activePlayer else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    AvatarView(name: player.name,
                               colorIndex: player.avatarIndex,
                               size: 48,
                               active: true,
                               photoData: session?.photoData(for: player.id))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NOW ROLLING")
                            .font(.ui(10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color.walnutInk.opacity(0.7))
                        Text(player.name)
                            .font(.display(32, italic: true))
                            .foregroundStyle(Color.walnutInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if game.isInFinalRound, let bar = game.scoreToBeat {
                            Text("BEAT")
                                .font(.ui(9, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color.gold)
                            MonoScoreText(value: bar, size: 18, weight: .bold, color: .gold2)
                            Text("you: \(player.bankedScore.formatted())")
                                .font(.mono(10))
                                .foregroundStyle(Color.walnutInk.opacity(0.7))
                        } else {
                            Text("BANKED")
                                .font(.ui(9, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color.walnutInk.opacity(0.7))
                            MonoScoreText(value: player.bankedScore, size: 18, weight: .bold, color: .walnutInk)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.walnut)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.walnut.opacity(0.4), radius: 18, x: 0, y: 6)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gold)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulse ? 1.4 : 1)
                        .opacity(pulse ? 0.2 : 1)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    Text("ROLLING")
                        .font(.mono(9, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(Color.walnutInk.opacity(0.85))
                }
                .padding(14)
            }
            .id(player.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity))
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: player.id)
            .onAppear { pulse = true }
        )
    }
}
