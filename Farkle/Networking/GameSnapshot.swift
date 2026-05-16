import Foundation

/// Wire format the host broadcasts to viewers. Full state — small enough that
/// re-sending on every change is fine and immune to diff bugs.
///
/// `seq` is monotonic per host session; viewers drop stale messages.
struct GameSnapshot: Codable, Equatable {
    var seq: Int
    var roomCode: String
    var hostName: String
    var gameID: UUID
    var gameName: String
    var targetScore: Int
    var rules: HouseRules

    var players: [PlayerSnapshot]
    var activePlayerID: UUID?
    var pendingTurnScore: Int
    var pendingRollCount: Int

    var finalRoundTriggeredByPlayerID: UUID?
    var finalRoundTurnsRemaining: Int
    var scoreToBeat: Int?

    var recentActions: [ActionSnapshot]   // newest last

    var endedAt: Date?
    var winnerPlayerID: UUID?

    var isInFinalRound: Bool {
        finalRoundTriggeredByPlayerID != nil && endedAt == nil
    }
}

struct PlayerSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var avatarIndex: Int
    var orderIndex: Int
    var bankedScore: Int
    var hotDiceCount: Int
    var farkleCount: Int
}

struct ActionSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var playerID: UUID
    var playerName: String
    var kindRaw: String
    var amount: Int
    var hotDice: Bool
    var timestamp: Date
    var orderIndex: Int

    var kind: ActionKind {
        ActionKind(rawValue: kindRaw) ?? .bank
    }
}

extension GameSnapshot {
    /// Build a snapshot from a live Game. `seq` is incremented externally.
    init(game: Game, seq: Int, roomCode: String, hostName: String) {
        self.seq = seq
        self.roomCode = roomCode
        self.hostName = hostName
        self.gameID = game.id
        self.gameName = game.name
        self.targetScore = game.targetScore
        self.rules = game.rules
        self.players = game.orderedPlayers.map {
            PlayerSnapshot(id: $0.id,
                           name: $0.name,
                           avatarIndex: $0.avatarIndex,
                           orderIndex: $0.orderIndex,
                           bankedScore: $0.bankedScore,
                           hotDiceCount: $0.hotDiceCount,
                           farkleCount: $0.farkleCount)
        }
        self.activePlayerID = game.activePlayer?.id
        self.pendingTurnScore = game.pendingTurnScore
        self.pendingRollCount = game.pendingRollCount
        self.finalRoundTriggeredByPlayerID = game.finalRoundTriggeredByPlayerID
        self.finalRoundTurnsRemaining = game.finalRoundTurnsRemaining
        self.scoreToBeat = game.scoreToBeat
        self.recentActions = Array(
            game.orderedActions.suffix(15).map { entry in
                let pname = game.players.first(where: { $0.id == entry.playerID })?.name ?? "—"
                return ActionSnapshot(
                    id: entry.id,
                    playerID: entry.playerID,
                    playerName: pname,
                    kindRaw: entry.kindRaw,
                    amount: entry.amount,
                    hotDice: entry.hotDice,
                    timestamp: entry.timestamp,
                    orderIndex: entry.orderIndex
                )
            }
        )
        self.endedAt = game.endedAt
        self.winnerPlayerID = game.winnerPlayerID
    }
}
