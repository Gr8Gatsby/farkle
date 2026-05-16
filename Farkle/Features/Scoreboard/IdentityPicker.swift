import SwiftUI

/// What the joiner picked when entering the scoreboard.
enum JoinerIdentity: Equatable, Hashable {
    case player(UUID)
    case spectator
}

/// Full-screen pick presented to a joiner the first time the scoreboard loads.
/// Local-only — the host doesn't see who picked which seat (in v1).
struct IdentityPickerOverlay: View {
    let snapshot: GameSnapshot
    var onPick: (JoinerIdentity) -> Void

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()
            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.28)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(snapshot.players.sorted(by: { $0.orderIndex < $1.orderIndex })) { player in
                            playerRow(player: player)
                        }
                        spectatorRow
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("LIVE SCOREBOARD")
                .font(.ui(11, weight: .bold))
                .tracking(2.2)
                .foregroundStyle(Color.gold)
            (
                Text("Who are ").font(.display(34))
                    .foregroundStyle(Color.paper) +
                Text("you?").font(.display(34, italic: true))
                    .foregroundStyle(Color.gold2)
            )
            .multilineTextAlignment(.center)
            Text("Pick your seat at the table — or just watch.")
                .font(.ui(12))
                .foregroundStyle(Color.paper.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func playerRow(player: PlayerSnapshot) -> some View {
        Button {
            onPick(.player(player.id))
        } label: {
            HStack(spacing: 14) {
                AvatarView(name: player.name, colorIndex: player.avatarIndex, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("I'm \(player.name)")
                        .font(.display(22, italic: true))
                        .foregroundStyle(Color.paper)
                    Text("\(player.bankedScore.formatted()) banked")
                        .font(.mono(11))
                        .foregroundStyle(Color.paper.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.paper.opacity(0.55))
            }
            .padding(14)
            .background(Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paper.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var spectatorRow: some View {
        Button {
            onPick(.spectator)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "eyes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.paper.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Just watching")
                        .font(.display(22, italic: true))
                        .foregroundStyle(Color.paper)
                    Text("Cheer or heckle, no pressure.")
                        .font(.ui(11))
                        .foregroundStyle(Color.paper.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.paper.opacity(0.55))
            }
            .padding(14)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paper.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
