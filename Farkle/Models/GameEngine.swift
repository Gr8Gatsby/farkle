import Foundation
import SwiftData

@MainActor
struct GameEngine {
    let game: Game
    let context: ModelContext

    func bank(hotDice: Bool = false) {
        guard let player = game.activePlayer else { return }
        let amount = game.pendingTurnScore
        guard amount > 0 else { return }
        if let mustOpen = game.rules.mustOpenWith, player.bankedScore == 0, amount < mustOpen { return }

        let entry = ActionLogEntry(playerID: player.id,
                                   kind: .bank,
                                   amount: amount,
                                   orderIndex: game.actions.count,
                                   roundNumber: game.currentRound,
                                   hotDice: hotDice,
                                   pendingTurnAtAction: amount)
        game.actions.append(entry)
        player.bankedScore += amount
        if hotDice { player.hotDiceCount += 1 }
        game.pendingTurnScore = 0
        game.pendingRollCount = 0

        if game.finalRoundTriggeredByPlayerID == nil, player.bankedScore >= game.targetScore {
            game.finalRoundTriggeredByPlayerID = player.id
            game.finalRoundTurnsRemaining = max(0, game.orderedPlayers.count - 1)
            game.finalRoundAnnouncementShown = false
            let trigger = ActionLogEntry(playerID: player.id,
                                         kind: .startFinalRound,
                                         amount: 0,
                                         orderIndex: game.actions.count,
                                         roundNumber: game.currentRound,
                                         pendingTurnAtAction: 0)
            game.actions.append(trigger)
        } else if game.finalRoundTriggeredByPlayerID != nil {
            game.finalRoundTurnsRemaining = max(0, game.finalRoundTurnsRemaining - 1)
        }

        advancePlayerOrEndGame()
        save()
    }

    func bust() {
        guard let player = game.activePlayer else { return }
        let snapshot = game.pendingTurnScore
        let entry = ActionLogEntry(playerID: player.id,
                                   kind: .bust,
                                   amount: 0,
                                   orderIndex: game.actions.count,
                                   roundNumber: game.currentRound,
                                   pendingTurnAtAction: snapshot)
        game.actions.append(entry)
        player.farkleCount += 1
        game.pendingTurnScore = 0
        game.pendingRollCount = 0

        if game.finalRoundTriggeredByPlayerID != nil {
            game.finalRoundTurnsRemaining = max(0, game.finalRoundTurnsRemaining - 1)
        }
        advancePlayerOrEndGame()
        save()
    }

    func addToPending(_ amount: Int) {
        guard amount > 0 else { return }
        game.pendingTurnScore += amount
        game.pendingRollCount += 1
        save()
    }

    func setPending(_ amount: Int) {
        game.pendingTurnScore = max(0, amount)
        save()
    }

    func clearPending() {
        game.pendingTurnScore = 0
        game.pendingRollCount = 0
        save()
    }

    /// Undo the most recent action. Returns true if something was undone.
    @discardableResult
    func undoLast() -> Bool {
        guard let last = game.orderedActions.last else { return false }
        return undo(through: last.orderIndex)
    }

    /// Undo the specific action by id, plus everything after it.
    @discardableResult
    func undo(actionID: UUID) -> Bool {
        guard let target = game.actions.first(where: { $0.id == actionID }) else { return false }
        return undo(through: target.orderIndex)
    }

    private func undo(through orderIndex: Int) -> Bool {
        let toRemove = game.actions.filter { $0.orderIndex >= orderIndex }
        guard !toRemove.isEmpty else { return false }
        let removeIDs = Set(toRemove.map(\.id))
        game.actions.removeAll { removeIDs.contains($0.id) }
        for a in toRemove { context.delete(a) }
        rebuildDerivedState()
        save()
        return true
    }

    private func rebuildDerivedState() {
        for p in game.players {
            p.bankedScore = 0
            p.hotDiceCount = 0
            p.farkleCount = 0
        }
        game.activePlayerIndex = 0
        game.pendingTurnScore = 0
        game.pendingRollCount = 0
        game.finalRoundTriggeredByPlayerID = nil
        game.finalRoundTurnsRemaining = 0
        game.finalRoundAnnouncementShown = true
        game.winnerPlayerID = nil
        game.endedAt = nil

        let ordered = game.orderedActions
        let players = game.orderedPlayers
        var activeIdx = 0

        for entry in ordered {
            guard let player = players.first(where: { $0.id == entry.playerID }) else { continue }
            switch entry.kind {
            case .bank:
                player.bankedScore += entry.amount
                if entry.hotDice { player.hotDiceCount += 1 }
                if game.finalRoundTriggeredByPlayerID != nil {
                    game.finalRoundTurnsRemaining = max(0, game.finalRoundTurnsRemaining - 1)
                }
                activeIdx = (activeIdx + 1) % max(1, players.count)
            case .bust:
                player.farkleCount += 1
                if game.finalRoundTriggeredByPlayerID != nil {
                    game.finalRoundTurnsRemaining = max(0, game.finalRoundTurnsRemaining - 1)
                }
                activeIdx = (activeIdx + 1) % max(1, players.count)
            case .startFinalRound:
                game.finalRoundTriggeredByPlayerID = entry.playerID
                game.finalRoundTurnsRemaining = max(0, players.count - 1)
                game.finalRoundAnnouncementShown = false
            case .endGame:
                game.endedAt = entry.timestamp
                game.winnerPlayerID = entry.playerID
            }
        }
        game.activePlayerIndex = activeIdx
    }

    private func advancePlayerOrEndGame() {
        let players = game.orderedPlayers
        guard !players.isEmpty else { return }

        if game.finalRoundTriggeredByPlayerID != nil, game.finalRoundTurnsRemaining <= 0 {
            // game over
            let leader = players.max(by: { $0.bankedScore < $1.bankedScore })
            game.winnerPlayerID = leader?.id
            game.endedAt = Date()
            let endEntry = ActionLogEntry(playerID: leader?.id ?? UUID(),
                                          kind: .endGame,
                                          amount: leader?.bankedScore ?? 0,
                                          orderIndex: game.actions.count,
                                          roundNumber: game.currentRound)
            game.actions.append(endEntry)
        } else {
            game.activePlayerIndex = (game.activePlayerIndex + 1) % players.count
        }
    }

    /// Called after the user dismisses the final-round announcement screen.
    func markFinalRoundAnnouncementShown() {
        game.finalRoundAnnouncementShown = true
        save()
    }

    /// Replace the amount on a past bank action. The action keeps its slot in the log,
    /// player order isn't affected; derived totals are rebuilt by replay. No-op for
    /// non-bank actions and for non-positive amounts.
    @discardableResult
    func setActionAmount(actionID: UUID, newAmount: Int) -> Bool {
        guard let target = game.actions.first(where: { $0.id == actionID }),
              target.kind == .bank,
              newAmount > 0 else { return false }
        target.amount = newAmount
        target.pendingTurnAtAction = newAmount
        rebuildDerivedState()
        save()
        return true
    }

    func renamePlayer(_ player: Player, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        player.name = String(trimmed.prefix(20))
        save()
    }

    private func save() {
        try? context.save()
    }
}
