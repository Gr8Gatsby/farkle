import Foundation
import SwiftData

enum ActionKind: String, Codable {
    case bank
    case bust
    case startFinalRound
    case endGame
}

@Model
final class ActionLogEntry {
    @Attribute(.unique) var id: UUID
    var playerID: UUID
    var kindRaw: String
    var amount: Int
    var timestamp: Date
    var orderIndex: Int
    var roundNumber: Int
    var hotDice: Bool
    var pendingTurnAtAction: Int

    var kind: ActionKind {
        get { ActionKind(rawValue: kindRaw) ?? .bank }
        set { kindRaw = newValue.rawValue }
    }

    init(playerID: UUID,
         kind: ActionKind,
         amount: Int,
         orderIndex: Int,
         roundNumber: Int,
         hotDice: Bool = false,
         pendingTurnAtAction: Int = 0) {
        self.id = UUID()
        self.playerID = playerID
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.timestamp = Date()
        self.orderIndex = orderIndex
        self.roundNumber = roundNumber
        self.hotDice = hotDice
        self.pendingTurnAtAction = pendingTurnAtAction
    }
}
