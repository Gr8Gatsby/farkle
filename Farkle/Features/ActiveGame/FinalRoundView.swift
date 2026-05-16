import SwiftUI
import SwiftData

/// The "special screen" used for every remaining player's last roll once the
/// target has been crossed. Felt-green theme, prominent score-to-beat coaching,
/// and the same bank / bust / score-helper controls as the regular game.
struct FinalRoundView: View {
    @Bindable var game: Game
    var onExit: () -> Void
    @Bindable var session: FarkleNetSession

    @Environment(\.modelContext) private var context
    @State private var showBankConfirm = false
    @State private var showBustConfirm = false
    @State private var showScoreHelper = false
    @State private var showKeypad = false
    @State private var showExitConfirm = false
    @State private var showInvite = false
    @State private var markHotDice = false
    @State private var actionBeingEdited: ActionLogEntry?

    private var engine: GameEngine { GameEngine(game: game, context: context) }

    private var trigger: Player? {
        guard let id = game.finalRoundTriggeredByPlayerID else { return nil }
        return game.players.first(where: { $0.id == id })
    }
    private var scoreToBeat: Int { game.scoreToBeat ?? game.targetScore }

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()
            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.25)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        hero
                        currentPlayerCard
                        pendingTurnPanel
                        remainingPanel
                        if !recentActions.isEmpty { recentSection }
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
                bottomBar
            }
        }
        .sheet(isPresented: $showBankConfirm) {
            BankConfirmSheet(
                game: game,
                hotDice: markHotDice,
                onConfirm: {
                    engine.bank(hotDice: markHotDice)
                    markHotDice = false
                    showBankConfirm = false
                },
                onCancel: { showBankConfirm = false },
                session: session
            )
            .presentationDetents([.medium])
            .presentationBackground(Color.paper)
        }
        .sheet(isPresented: $showBustConfirm) {
            BustConfirmSheet(
                game: game,
                onConfirm: {
                    engine.bust()
                    markHotDice = false
                    showBustConfirm = false
                },
                onCancel: { showBustConfirm = false }
            )
            .presentationDetents([.fraction(0.4)])
            .presentationBackground(Color.paper)
        }
        .sheet(isPresented: $showScoreHelper) {
            ScoreHelperSheet(
                rules: game.rules,
                onAdd: { total, hot in
                    engine.addToPending(total)
                    if hot { markHotDice = true }
                    showScoreHelper = false
                },
                onCancel: { showScoreHelper = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.paper)
        }
        .sheet(isPresented: $showKeypad) {
            KeypadSheet(
                initial: 0,
                onAdd: { value in
                    engine.addToPending(value)
                    showKeypad = false
                },
                onCancel: { showKeypad = false }
            )
            .presentationDetents([.fraction(0.55)])
            .presentationBackground(Color.paper)
        }
        .sheet(item: $actionBeingEdited) { entry in
            EditActionSheet(
                game: game,
                action: entry,
                onSave: { newAmount in
                    engine.setActionAmount(actionID: entry.id, newAmount: newAmount)
                    actionBeingEdited = nil
                },
                onUndo: {
                    engine.undo(actionID: entry.id)
                    actionBeingEdited = nil
                },
                onCancel: { actionBeingEdited = nil },
                session: session
            )
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.paper)
        }
        .sheet(isPresented: $showInvite) {
            InviteViewersSheet(session: session) { showInvite = false }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Leave game?", isPresented: $showExitConfirm) {
            Button("Leave", role: .destructive) {
                session.stopHosting()
                onExit()
            }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("Your game is saved. You can resume it from Home.")
        }
        .onAppear {
            // Final-round screen IS the announcement now; mark it acknowledged so
            // the persisted flag stays consistent.
            if !game.finalRoundAnnouncementShown {
                engine.markFinalRoundAnnouncementShown()
            }
        }
    }

    // MARK: top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                showExitConfirm = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.10))
                    .foregroundStyle(Color.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            inviteButton
            Spacer()
            VStack(spacing: 0) {
                Text("FINAL ROUND · \(game.finalRoundTurnsRemaining) LEFT")
                    .font(.mono(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.gold)
            }
            Spacer()
            Button {
                engine.undoLast()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Undo")
                        .font(.ui(12, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Color.white.opacity(0.10))
                .foregroundStyle(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(game.actions.isEmpty)
            .opacity(game.actions.isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: hero

    private var hero: some View {
        VStack(spacing: 6) {
            Text("FINAL ROUND")
                .font(.ui(11, weight: .bold))
                .tracking(2.4)
                .foregroundStyle(Color.gold)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Beat")
                    .font(.display(28))
                    .foregroundStyle(Color.paper)
                Text(scoreToBeat.formatted())
                    .font(.display(40, italic: true))
                    .foregroundStyle(Color.gold2)
            }
            if let trigger {
                Text("\(trigger.name) set the bar.")
                    .font(.ui(12))
                    .foregroundStyle(Color.paper.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: current player

    @ViewBuilder
    private var currentPlayerCard: some View {
        if let player = game.activePlayer {
            let pending = game.pendingTurnScore
            let projected = player.bankedScore + pending

            HStack(spacing: 12) {
                AvatarView(name: player.name,
                           colorIndex: player.avatarIndex,
                           size: 56,
                           active: true,
                           photoData: session.photoData(for: player.id))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ROLLING NOW")
                        .font(.ui(10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color.gold)
                    Text(player.name)
                        .font(.display(28, italic: true))
                        .foregroundStyle(Color.paper)
                    Text("at \(player.bankedScore.formatted()) — beat \(scoreToBeat.formatted()) to win")
                        .font(.ui(12))
                        .foregroundStyle(Color.paper.opacity(0.75))
                }
                Spacer()
                if projected > scoreToBeat && pending > 0 {
                    Text("WIN")
                        .font(.mono(11, weight: .bold))
                        .tracking(1.4)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gold)
                        .foregroundStyle(Color.walnut)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gold.opacity(0.45), lineWidth: 1)
            )
        }
    }

    // MARK: pending turn

    private var pendingTurnPanel: some View {
        PendingTurnCard(
            game: game,
            markHotDice: $markHotDice,
            onQuickAdd: { engine.addToPending($0) },
            onClear: { engine.clearPending() },
            onOpenHelper: { showScoreHelper = true },
            onOpenKeypad: { showKeypad = true }
        )
    }

    // MARK: remaining players

    @ViewBuilder
    private var remainingPanel: some View {
        // Exclude the player currently rolling — they're shown in the hero card above.
        let queue = game.remainingFinalRoundPlayers.filter { $0.id != game.activePlayer?.id }
        if !queue.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("STILL TO ROLL")
                    .font(.ui(10, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color.paper.opacity(0.55))
                    .padding(.horizontal, 4)
                VStack(spacing: 0) {
                    ForEach(Array(queue.enumerated()), id: \.element.id) { idx, player in
                        rowRemaining(player: player, isNext: idx == 0)
                        if idx < queue.count - 1 {
                            Rectangle().fill(Color.paper.opacity(0.08)).frame(height: 0.5)
                        }
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.paper.opacity(0.06), lineWidth: 0.5)
                )
            }
        }
    }

    private func rowRemaining(player: Player, isNext: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarView(name: player.name,
                       colorIndex: player.avatarIndex,
                       size: 24,
                       active: isNext,
                       photoData: session.photoData(for: player.id))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.ui(13, weight: .semibold))
                        .foregroundStyle(Color.paper)
                    if isNext {
                        Text("UP NEXT")
                            .font(.mono(8, weight: .bold))
                            .tracking(0.6)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.gold)
                            .foregroundStyle(Color.walnut)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                }
                Text("at \(player.bankedScore.formatted()) · beat \(scoreToBeat.formatted())")
                    .font(.ui(10))
                    .foregroundStyle(Color.paper.opacity(0.65))
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    // MARK: recent (final-round only)

    private var recentActions: [ActionLogEntry] {
        guard let trigger = game.finalRoundTriggeredByPlayerID else { return [] }
        // Show the triggering bank + everything after it.
        let ordered = game.orderedActions
        guard let triggerIdx = ordered.firstIndex(where: {
            $0.kind == .bank && $0.playerID == trigger
        }) else { return [] }
        return Array(ordered[triggerIdx...].reversed())
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FINAL ROUND TURNS")
                    .font(.ui(10, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color.paper.opacity(0.55))
                Spacer()
                Text("Tap to edit / undo")
                    .font(.ui(10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.paper.opacity(0.45))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 4) {
                ForEach(recentActions.prefix(5), id: \.id) { entry in
                    actionRow(entry: entry)
                }
            }
        }
    }

    private func actionRow(entry: ActionLogEntry) -> some View {
        let player = game.players.first(where: { $0.id == entry.playerID })
        return Button {
            actionBeingEdited = entry
        } label: {
            HStack(spacing: 10) {
                AvatarView(name: player?.name ?? "?",
                           colorIndex: player?.avatarIndex ?? 0,
                           size: 20,
                           photoData: player.flatMap { session.photoData(for: $0.id) })
                HStack(spacing: 4) {
                    Text(player?.name ?? "—")
                        .font(.ui(12, weight: .semibold))
                        .foregroundStyle(Color.paper)
                    Group {
                        switch entry.kind {
                        case .bank:
                            HStack(spacing: 4) {
                                Text("banked")
                                Text("+\(entry.amount.formatted())")
                                    .font(.mono(12, weight: .bold))
                                    .foregroundStyle(Color.gold2)
                            }
                        case .bust:
                            HStack(spacing: 4) {
                                Text("busted")
                                Text("(Farkle)").foregroundStyle(Color.crimson)
                            }
                        case .startFinalRound:
                            Text("triggered final round").foregroundStyle(Color.gold)
                        case .endGame:
                            Text("won the game").foregroundStyle(Color.gold)
                        }
                    }
                    .font(.ui(12))
                    .foregroundStyle(Color.paper.opacity(0.8))
                }
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.paper.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.paper.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: bottom bar

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {
                showBustConfirm = true
            } label: {
                VStack(spacing: 1) {
                    Text("FARKLE")
                        .font(.ui(10, weight: .bold))
                        .tracking(1.2)
                    Text("Bust turn")
                        .font(.display(14, italic: true))
                }
                .foregroundStyle(Color.crimson)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.crimson.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.crimson.opacity(0.40), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            Button {
                if canBank { showBankConfirm = true }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("BANK")
                            .font(.ui(9, weight: .bold))
                            .tracking(1.4)
                            .opacity(0.75)
                        if canBank, let player = game.activePlayer {
                            let newTotal = player.bankedScore + game.pendingTurnScore
                            Text("+\(game.pendingTurnScore) → \(newTotal.formatted())")
                                .font(.display(20, italic: true))
                            Text(hint(newTotal: newTotal))
                                .font(.ui(10, weight: .bold))
                                .tracking(0.6)
                                .opacity(0.9)
                        } else {
                            Text("Add some points first")
                                .font(.display(15, italic: true))
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color.walnutInk)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(Color.walnut)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.walnutShadow, radius: 0, x: 0, y: 3)
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .layoutPriority(1.6)
            .opacity(canBank ? 1 : 0.55)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 28)
    }

    private var inviteButton: some View {
        Button {
            showInvite = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 11, weight: .semibold))
                if !session.roomCode.isEmpty {
                    Text(session.roomCode)
                        .font(.mono(13, weight: .bold))
                        .tracking(1)
                }
                if session.connectedPeerCount > 0 {
                    Text("·").font(.ui(11, weight: .semibold)).opacity(0.6)
                    Image(systemName: "person.fill").font(.system(size: 10, weight: .semibold))
                    Text("\(session.connectedPeerCount)").font(.mono(12, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(session.connectedPeerCount > 0
                        ? Color.gold.opacity(0.85)
                        : Color.white.opacity(0.10))
            .foregroundStyle(session.connectedPeerCount > 0 ? Color.walnut : Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Room code \(session.roomCode). \(session.connectedPeerCount) viewers.")
    }

    private var canBank: Bool {
        guard game.pendingTurnScore > 0 else { return false }
        return true
    }

    private func hint(newTotal: Int) -> String {
        if newTotal > scoreToBeat { return "WINS!" }
        if newTotal == scoreToBeat { return "TIE — TRIGGER WINS" }
        return "SHORT BY \((scoreToBeat - newTotal).formatted())"
    }
}
