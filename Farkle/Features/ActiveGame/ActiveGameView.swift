import SwiftUI
import SwiftData

struct ActiveGameView: View {
    @Bindable var game: Game
    var onExit: () -> Void

    @Environment(\.modelContext) private var context
    @State private var showBankConfirm = false
    @State private var showBustConfirm = false
    @State private var showScoreHelper = false
    @State private var showKeypad = false
    @State private var showExitConfirm = false
    @State private var showInvite = false
    @State private var markHotDice = false
    @State private var actionBeingEdited: ActionLogEntry?
    @State private var netSession = FarkleNetSession()

    private var engine: GameEngine { GameEngine(game: game, context: context) }

    var body: some View {
        if game.endedAt != nil {
            GameOverView(game: game,
                         onUndo: {
                engine.undoLast()  // undoes endGame entry; rebuild restores game
            },
                         onExit: onExit,
                         onRematch: rematch)
        } else if game.isInFinalRound {
            FinalRoundView(game: game, onExit: onExit, session: netSession)
                .hostBroadcaster(game: game, session: netSession)
        } else {
            ZStack {
                PaperBackground()
                VStack(spacing: 0) {
                    topBar
                    ScrollView {
                        VStack(spacing: 14) {
                            NowRollingBanner(game: game)
                            PendingTurnCard(
                                game: game,
                                markHotDice: $markHotDice,
                                onQuickAdd: { engine.addToPending($0) },
                                onClear: { engine.clearPending() },
                                onOpenHelper: { showScoreHelper = true },
                                onOpenKeypad: { showKeypad = true }
                            )
                            StandingsLadder(game: game)
                            RecentActionsLog(game: game,
                                             onTap: { entry in actionBeingEdited = entry })
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
                    onCancel: { showBankConfirm = false }
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
                    onCancel: { actionBeingEdited = nil }
                )
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.paper)
            }
            .sheet(isPresented: $showInvite) {
                InviteViewersSheet(session: netSession) {
                    showInvite = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Leave game?", isPresented: $showExitConfirm) {
                Button("Leave", role: .destructive) {
                    netSession.stopHosting()
                    onExit()
                }
                Button("Stay", role: .cancel) {}
            } message: {
                Text("Your game is saved. You can resume it from Home.")
            }
            .hostBroadcaster(game: game, session: netSession)
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                showExitConfirm = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.walnut.opacity(0.08))
                    .foregroundStyle(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            inviteButton(dark: false)
            Spacer()
            VStack(spacing: 0) {
                if game.isInFinalRound {
                    Text("FINAL ROUND · \(game.finalRoundTurnsRemaining) LEFT")
                        .font(.mono(10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color.crimson)
                } else {
                    Text("R\(game.currentRound) · TO \(game.targetScore.formatted())")
                        .font(.mono(10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink3)
                }
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
                .background(Color.walnut.opacity(0.08))
                .foregroundStyle(Color.ink)
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
                .background(Color.crimson.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.crimson.opacity(0.25), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            Button {
                if canBank { showBankConfirm = true }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("REVIEW & BANK")
                            .font(.ui(9, weight: .bold))
                            .tracking(1.4)
                            .opacity(0.75)
                        if canBank, let player = game.activePlayer {
                            let newTotal = player.bankedScore + game.pendingTurnScore
                            Text("+\(game.pendingTurnScore) → \(newTotal.formatted())")
                                .font(.display(20, italic: true))
                            if let bar = game.scoreToBeat {
                                Text(finalRoundHint(newTotal: newTotal, bar: bar))
                                    .font(.ui(10, weight: .semibold))
                                    .tracking(0.6)
                                    .opacity(0.85)
                            }
                        } else if !canBank, let mustOpen = game.rules.mustOpenWith,
                                  let player = game.activePlayer, player.bankedScore == 0 {
                            Text("Must open with \(mustOpen)")
                                .font(.display(15, italic: true))
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
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
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

    @ViewBuilder
    private func inviteButton(dark: Bool) -> some View {
        Button {
            startHostingIfNeeded()
            showInvite = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: netSession.role == .host && netSession.connectedPeerCount > 0
                      ? "dot.radiowaves.left.and.right"
                      : "person.2.fill")
                    .font(.system(size: 11, weight: .semibold))
                if netSession.role == .host {
                    Text("\(netSession.connectedPeerCount)")
                        .font(.mono(11, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(netSession.role == .host && netSession.connectedPeerCount > 0
                        ? Color.felt.opacity(0.85)
                        : (dark ? Color.white.opacity(0.10) : Color.walnut.opacity(0.08)))
            .foregroundStyle(netSession.role == .host && netSession.connectedPeerCount > 0
                             ? Color.paper
                             : (dark ? Color.paper : Color.ink))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Invite viewers")
    }

    private func startHostingIfNeeded() {
        guard netSession.role == .idle else { return }
        let snapshot = GameSnapshot(
            game: game,
            seq: 0,
            roomCode: RoomCode.generate(),
            hostName: UIDevice.current.name
        )
        netSession.startHosting(initialSnapshot: snapshot)
    }

    private func finalRoundHint(newTotal: Int, bar: Int) -> String {
        if newTotal > bar { return "WINS! ▸" }
        let need = bar - newTotal + 1
        return "SHORT BY \(need.formatted())"
    }

    private var canBank: Bool {
        guard game.pendingTurnScore > 0, let player = game.activePlayer else { return false }
        if let mustOpen = game.rules.mustOpenWith, player.bankedScore == 0, game.pendingTurnScore < mustOpen {
            return false
        }
        return true
    }

    private func rematch() {
        let next = Game(name: Game.generateName(),
                        targetScore: game.targetScore,
                        rules: game.rules,
                        players: game.orderedPlayers.enumerated().map { idx, p in
                            Player(name: p.name, avatarIndex: p.avatarIndex, orderIndex: idx)
                        })
        context.insert(next)
        try? context.save()
        onExit()
    }
}
