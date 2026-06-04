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
    @State private var identity: JoinerIdentity?
    @State private var photoPickerPlayer: PlayerSnapshot?
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

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

            if identity == nil, let snap = snapshot, snap.endedAt == nil {
                IdentityPickerOverlay(snapshot: snap) { choice in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        identity = choice
                    }
                    if case .player(let id) = choice,
                       let player = snap.players.first(where: { $0.id == id }) {
                        // Send a claim immediately so the host sees who I am even
                        // without a photo. Photo step is optional and follows.
                        session.sendClaim(PlayerClaim(playerID: id, photoJPEG: nil))
                        photoPickerPlayer = player
                    }
                }
                .transition(.opacity)
            }

            // Only show the "host quit" overlay when the host disconnected
            // mid-game. If the snapshot already says the game ended, the joiner
            // is showing the win celebration and shouldn't be hijacked.
            if session.joinState == .hostEnded, snapshot?.endedAt == nil {
                hostEndedOverlay
            }
        }
        .onChange(of: snapshot, initial: false) { _, newSnap in
            if let newSnap {
                handleSnapshotChange(newSnap)
            }
        }
        .sheet(item: $photoPickerPlayer) { player in
            PlayerPhotoPickerSheet(
                player: player,
                currentPhotoData: snapshot?.photoData(for: player.id),
                onSave: { data in
                    session.sendClaim(PlayerClaim(playerID: player.id, photoJPEG: data))
                    photoPickerPlayer = nil
                },
                onCancel: { photoPickerPlayer = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
                    standingsList(snap: snap)
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
        let active = snap.players.first(where: { $0.id == snap.activePlayerID })
        let bar = snap.scoreToBeat ?? snap.targetScore
        let needs = active.map { bar - $0.bankedScore + 50 }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.walnut)
                    .frame(width: 48, height: 48)
                    .background(Color.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("FINAL ROUND")
                        .font(.mono(11, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(Color.gold)
                    if let active, let needs, needs > 0 {
                        Text("\(active.name) needs \(needs.formatted()) to win")
                            .font(.ui(18, weight: .bold))
                            .foregroundStyle(Color.paper)
                    }
                }
                Spacer()
            }
            if let needs, needs > 0, let active {
                Text(comboSuggestion(needed: needs, seed: active.id))
                    .font(.display(16, italic: true))
                    .foregroundStyle(Color.paper.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gold.opacity(0.45), lineWidth: 1)
        )
    }

    private func comboSuggestion(needed: Int, seed: UUID) -> String {
        struct Hand {
            let name: String
            let plural: String
            let value: Int
        }

        let hands: [Hand] = [
            Hand(name: "six-of-a-kind", plural: "six-of-a-kinds", value: 3000),
            Hand(name: "two triplets", plural: "double triplets", value: 2500),
            Hand(name: "five-of-a-kind", plural: "five-of-a-kinds", value: 2000),
            Hand(name: "a straight", plural: "straights", value: 1500),
            Hand(name: "three pairs", plural: "three-pair rolls", value: 1500),
            Hand(name: "four-of-a-kind", plural: "four-of-a-kinds", value: 1000),
            Hand(name: "three 6s", plural: "triple 6s", value: 600),
            Hand(name: "three 5s", plural: "triple 5s", value: 500),
            Hand(name: "three 4s", plural: "triple 4s", value: 400),
            Hand(name: "three 3s", plural: "triple 3s", value: 300),
            Hand(name: "three 1s", plural: "triple 1s", value: 300),
            Hand(name: "three 2s", plural: "triple 2s", value: 200),
        ]

        var rng = SeededRNG(seed: seed.hashValue)
        var shuffled = hands.shuffled(using: &rng)
        var remaining = needed
        var picks: [(String, Int)] = []

        while remaining > 0 && !shuffled.isEmpty && picks.count < 4 {
            if let idx = shuffled.firstIndex(where: { $0.value <= remaining }) {
                let hand = shuffled[idx]
                if let existing = picks.firstIndex(where: { $0.0 == hand.name }) {
                    picks[existing].1 += 1
                    remaining -= hand.value
                } else {
                    picks.append((hand.name, 1))
                    remaining -= hand.value
                }
            } else {
                shuffled.removeFirst()
            }
        }

        if remaining > 0 {
            let ones = (remaining + 99) / 100
            if ones == 1 {
                picks.append(("a lucky 1", 1))
            } else {
                picks.append(("\(ones) lucky 1s", 1))
            }
        }

        let parts = picks.map { name, count -> String in
            if count == 1 { return name }
            let hand = hands.first(where: { $0.name == name })
            return "\(count) \(hand?.plural ?? name)"
        }

        let combo: String
        if parts.count == 1 {
            combo = parts[0]
        } else {
            combo = parts.dropLast().joined(separator: ", ") + ", and " + parts.last!
        }

        let prefixes = [
            "Just roll ", "All you need is ", "Easy — just roll ",
            "No big deal, just ", "Simple — ",
        ]
        let suffixes = [
            " Easy!", " No sweat.", " Simple.", " What could go wrong?",
            " Totally doable.", " You got this.",
        ]
        let prefix = prefixes[abs(seed.hashValue) % prefixes.count]
        let suffix = suffixes[abs(seed.hashValue / 7) % suffixes.count]

        return "\(prefix)\(combo).\(suffix)"
    }

    // MARK: - Standings list

    private func standingsList(snap: GameSnapshot) -> some View {
        let ranked = snap.players.sorted { $0.bankedScore > $1.bankedScore }
        return VStack(spacing: 0) {
            ForEach(Array(ranked.enumerated()), id: \.element.id) { idx, player in
                standingsRow(player: player, rank: idx + 1, snap: snap)
                if idx < ranked.count - 1 {
                    Rectangle().fill(Color.paper.opacity(0.06)).frame(height: 0.5)
                }
            }
        }
        .background(Color.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.paper.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func standingsRow(player: PlayerSnapshot, rank: Int, snap: GameSnapshot) -> some View {
        let isActive = player.id == snap.activePlayerID
        let isMe = identity == .player(player.id)
        let pending = isActive ? snap.pendingTurnScore : 0
        let avatarSize: CGFloat = isActive ? 40 : 28

        return HStack(spacing: 10) {
            ZStack {
                AvatarView(name: player.name,
                           colorIndex: player.avatarIndex,
                           size: avatarSize,
                           active: isActive,
                           photoData: snap.photoData(for: player.id))
                    .opacity(isActive ? 0 : 1)
                    .onTapGesture { if isMe { photoPickerPlayer = player } }
                Image(systemName: "dice.fill")
                    .font(.system(size: avatarSize * 0.55, weight: .semibold))
                    .foregroundStyle(Color.gold)
                    .frame(width: avatarSize, height: avatarSize)
                    .opacity(isActive ? 1 : 0)
            }
            .frame(width: avatarSize, height: avatarSize)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(isActive ? .ui(16, weight: .bold) : .ui(14, weight: .medium))
                        .foregroundStyle(Color.paper)
                    if isMe {
                        Text("YOU")
                            .font(.mono(8, weight: .bold))
                            .tracking(0.6)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.paper)
                            .foregroundStyle(Color.felt)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                }
                if isActive, pending > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(pending.formatted())
                            .font(.mono(11, weight: .bold))
                    }
                    .foregroundStyle(Color.gold)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: pending)
                }
            }

            Spacer()

            AnimatedScoreText(value: player.bankedScore,
                              size: isActive ? 28 : 18,
                              color: .paper)
                .animation(.easeInOut(duration: 0.6), value: player.bankedScore)

            Text(ordinal(rank))
                .font(.mono(10, weight: .bold))
                .foregroundStyle(rank == 1 ? Color.walnut : Color.paper.opacity(0.6))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(rank == 1 ? Color.gold.opacity(0.8) : Color.paper.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, isActive ? 14 : 10)
        .background(isActive ? Color.black.opacity(0.15) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isActive ? Color.gold.opacity(0.6) : Color.clear, lineWidth: 1.5)
                .padding(2)
        )
        .animation(.easeInOut(duration: 0.4), value: isActive)
    }

    private func ordinal(_ n: Int) -> String {
        let ones = n % 10
        let tens = (n / 10) % 10
        let suffix: String
        if tens == 1 { suffix = "th" }
        else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
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
            VStack(spacing: 16) {
                Spacer(minLength: 12)
                Text("FARKLE")
                    .font(.ui(14, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(Color.gold)
                if let winner {
                    winnerCrest(winner: winner, snap: snap)
                    (
                        Text("\(winner.name)\n").font(.display(56, italic: true))
                            .foregroundStyle(Color.paper) +
                        Text("wins.").font(.display(56))
                            .foregroundStyle(Color.gold2)
                    )
                    .multilineTextAlignment(.center)
                    .lineSpacing(-10)
                    Text(winner.bankedScore.formatted())
                        .font(.mono(32, weight: .bold))
                        .foregroundStyle(Color.gold2)
                }
                Spacer()
                shareButton(snap: snap)
                doneButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image, shareCaption(snap: snap)])
            }
        }
    }

    private func winnerCrest(winner: PlayerSnapshot, snap: GameSnapshot) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.gold.opacity(0.35), .clear],
                                     center: .center, startRadius: 0, endRadius: 140))
                .frame(width: 260, height: 260)
            AvatarView(name: winner.name,
                       colorIndex: winner.avatarIndex,
                       size: 140,
                       active: true,
                       photoData: snap.photoData(for: winner.id))
                .shadow(color: Color.gold.opacity(0.6), radius: 22)
            Image(systemName: "trophy.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.walnut)
                .padding(12)
                .background(Color.gold)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.paper, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
                .offset(x: 54, y: 54)
        }
        .frame(width: 260, height: 260)
    }

    private func shareButton(snap: GameSnapshot) -> some View {
        Button {
            renderAndShare(snap: snap)
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
    }

    private var doneButton: some View {
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
    }

    @MainActor
    private func renderAndShare(snap: GameSnapshot) {
        shareImage = WinImageRenderer.image(for: snap)
        if shareImage != nil { showShareSheet = true }
    }

    private func shareCaption(snap: GameSnapshot) -> String {
        if let id = snap.winnerPlayerID,
           let winner = snap.players.first(where: { $0.id == id }) {
            return "\(winner.name) won our Farkle game at \(winner.bankedScore.formatted())."
        }
        return "Farkle win!"
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

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed)) | 1 }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
