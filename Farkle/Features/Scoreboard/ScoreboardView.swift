import SwiftUI

/// Read-only live scoreboard shown on joiner devices. Animates score tickers,
/// highlights the active player, plays a feed of flavor messages, and mirrors
/// the win celebration when the host's game ends.
struct ScoreboardView: View {
    @Bindable var session: FarkleNetSession
    var onLeave: () -> Void

    @State private var previousSnapshot: GameSnapshot?
    @State private var flavorQueue: [FlavorMessage] = []
    @State private var currentFlavor: FlavorMessage?
    @State private var liveFeed: [ActionSnapshot] = []

    private var snapshot: GameSnapshot? { session.latestSnapshot }

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()
            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.30)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            if let snap = snapshot {
                if snap.endedAt != nil { winCelebration(snap: snap) }
                else { board(snap: snap) }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.paper)
            }

            if session.joinState == .hostEnded {
                hostEndedOverlay
            }
        }
        .onChange(of: snapshot, initial: false) { _, newSnap in
            if let newSnap {
                handleSnapshotChange(newSnap)
            }
        }
    }

    private func handleSnapshotChange(_ newSnap: GameSnapshot) {
        let messages = FlavorMessageMaker.diff(previous: previousSnapshot, current: newSnap)
        flavorQueue.append(contentsOf: messages)
        previousSnapshot = newSnap
        liveFeed = newSnap.recentActions.reversed()
        pumpFlavor()
    }

    private func pumpFlavor() {
        guard currentFlavor == nil, let next = flavorQueue.first else { return }
        flavorQueue.removeFirst()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentFlavor = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                currentFlavor = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { pumpFlavor() }
        }
    }

    // MARK: - Board

    private func board(snap: GameSnapshot) -> some View {
        VStack(spacing: 0) {
            header(snap: snap)
            ScrollView {
                VStack(spacing: 14) {
                    if snap.isInFinalRound { finalRoundBanner(snap: snap) }
                    playersGrid(snap: snap)
                    pendingTurnIndicator(snap: snap)
                    feedSection
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
            leaveButton
        }
        .overlay(alignment: .top) {
            if let flavor = currentFlavor {
                flavorBubble(flavor)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func header(snap: GameSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(snap.gameName)
                    .font(.display(22, italic: true))
                    .foregroundStyle(Color.paper)
                Text("hosted by \(snap.hostName) · target \(snap.targetScore.formatted())")
                    .font(.ui(10))
                    .foregroundStyle(Color.paper.opacity(0.6))
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Color.gold)
                    .frame(width: 8, height: 8)
                    .modifier(PulsingDot())
                Text("LIVE")
                    .font(.mono(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.gold)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func finalRoundBanner(snap: GameSnapshot) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.walnut)
                .frame(width: 36, height: 36)
                .background(Color.gold)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text("FINAL ROUND · \(snap.finalRoundTurnsRemaining) LEFT")
                    .font(.mono(10, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color.gold)
                if let bar = snap.scoreToBeat {
                    Text("Beat \(bar.formatted()) to win.")
                        .font(.ui(13, weight: .semibold))
                        .foregroundStyle(Color.paper)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.black.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gold.opacity(0.45), lineWidth: 1)
        )
    }

    private func playersGrid(snap: GameSnapshot) -> some View {
        let columns = snap.players.count <= 4 ? 2 : 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(snap.players.sorted(by: { $0.orderIndex < $1.orderIndex })) { p in
                playerCard(player: p, snap: snap)
                    .id(p.id)
            }
        }
    }

    private func playerCard(player: PlayerSnapshot, snap: GameSnapshot) -> some View {
        let isActive = player.id == snap.activePlayerID
        let pending = isActive ? snap.pendingTurnScore : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AvatarView(name: player.name, colorIndex: player.avatarIndex, size: 30, active: isActive)
                Text(player.name)
                    .font(.ui(13, weight: .semibold))
                    .foregroundStyle(Color.paper)
                Spacer()
                if isActive {
                    Text("ROLLING")
                        .font(.mono(8, weight: .bold))
                        .tracking(0.6)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gold)
                        .foregroundStyle(Color.walnut)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
            }
            AnimatedScoreText(value: player.bankedScore, size: 34)
                .animation(.easeInOut(duration: 0.6), value: player.bankedScore)
            if pending > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text(pending.formatted())
                        .font(.mono(11, weight: .bold))
                }
                .foregroundStyle(Color.gold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.gold.opacity(0.18))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(isActive ? 0.35 : 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isActive ? Color.gold.opacity(0.85) : Color.paper.opacity(0.06),
                        lineWidth: isActive ? 1.5 : 0.5)
        )
        .shadow(color: isActive ? Color.gold.opacity(0.4) : .clear, radius: isActive ? 12 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .animation(.easeInOut(duration: 0.25), value: pending)
    }

    @ViewBuilder
    private func pendingTurnIndicator(snap: GameSnapshot) -> some View {
        if let activeID = snap.activePlayerID,
           let active = snap.players.first(where: { $0.id == activeID }),
           snap.pendingTurnScore > 0 {
            HStack(spacing: 10) {
                Image(systemName: "dice")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.gold)
                Text("\(active.name) has")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper.opacity(0.75))
                AnimatedScoreText(value: snap.pendingTurnScore, size: 18, color: Color.gold2)
                    .animation(.easeInOut(duration: 0.35), value: snap.pendingTurnScore)
                Text("pending")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper.opacity(0.75))
                Spacer()
            }
            .padding(12)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LIVE FEED")
                .font(.ui(10, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Color.paper.opacity(0.55))
            VStack(spacing: 4) {
                if liveFeed.isEmpty {
                    Text("Watching for the first roll…")
                        .font(.ui(12))
                        .foregroundStyle(Color.paper.opacity(0.55))
                        .padding(.vertical, 8)
                } else {
                    ForEach(liveFeed.prefix(8)) { action in
                        feedRow(action: action)
                    }
                }
            }
        }
    }

    private func feedRow(action: ActionSnapshot) -> some View {
        HStack(spacing: 8) {
            switch action.kind {
            case .bank:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.gold2)
                Text("\(action.playerName) banked")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper)
                Text("+\(action.amount.formatted())")
                    .font(.mono(12, weight: .bold))
                    .foregroundStyle(Color.gold2)
                if action.hotDice {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gold)
                }
            case .bust:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.crimson)
                Text("\(action.playerName) farkled")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper)
            case .startFinalRound:
                Image(systemName: "flag.checkered")
                    .foregroundStyle(Color.gold)
                Text("\(action.playerName) triggered the final round")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper)
            case .endGame:
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.gold)
                Text("\(action.playerName) won the game")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper)
            }
            Spacer()
            Text(relativeTime(action.timestamp))
                .font(.mono(10))
                .foregroundStyle(Color.paper.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    private var leaveButton: some View {
        Button {
            session.leaveSession()
            onLeave()
        } label: {
            Text("Leave scoreboard")
                .font(.ui(13, weight: .semibold))
                .foregroundStyle(Color.paper.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }

    // MARK: - Flavor

    private func flavorBubble(_ msg: FlavorMessage) -> some View {
        Text(msg.text)
            .font(.display(18, italic: true))
            .foregroundStyle(Color.walnut)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gold)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 24)
    }

    // MARK: - Win

    private func winCelebration(snap: GameSnapshot) -> some View {
        let winner = snap.players.first(where: { $0.id == snap.winnerPlayerID })
        return ZStack {
            ConfettiView()
            VStack(spacing: 20) {
                Spacer()
                Text("FARKLE")
                    .font(.ui(14, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(Color.gold)
                if let winner {
                    AvatarView(name: winner.name, colorIndex: winner.avatarIndex, size: 110, active: true)
                        .shadow(color: Color.gold.opacity(0.5), radius: 30)
                    (
                        Text("\(winner.name)\n").font(.display(64, italic: true))
                            .foregroundStyle(Color.paper) +
                        Text("wins.").font(.display(64))
                            .foregroundStyle(Color.gold2)
                    )
                    .multilineTextAlignment(.center)
                    .lineSpacing(-12)
                    Text(winner.bankedScore.formatted())
                        .font(.mono(36, weight: .bold))
                        .foregroundStyle(Color.gold2)
                }
                Spacer()
                Button {
                    session.leaveSession()
                    onLeave()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.10))
                        .foregroundStyle(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.paper.opacity(0.2), lineWidth: 0.5)
                        )
                        .font(.ui(14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Host ended

    private var hostEndedOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Host ended the game.")
                    .font(.display(24, italic: true))
                    .foregroundStyle(Color.paper)
                Button("Done") {
                    session.leaveSession()
                    onLeave()
                }
                .buttonStyle(WalnutButtonStyle(size: .regular))
            }
            .padding(24)
            .background(Color.felt)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct PulsingDot: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .opacity(on ? 0.3 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}
