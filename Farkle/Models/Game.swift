import Foundation
import SwiftData

@Model
final class Game {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var endedAt: Date?
    var targetScore: Int
    var rulesData: Data
    @Relationship(deleteRule: .cascade) var players: [Player] = []
    @Relationship(deleteRule: .cascade) var actions: [ActionLogEntry] = []
    var activePlayerIndex: Int
    var pendingTurnScore: Int
    var pendingRollCount: Int
    var finalRoundTriggeredByPlayerID: UUID?
    var finalRoundTurnsRemaining: Int
    var winnerPlayerID: UUID?

    var rules: HouseRules {
        get { (try? JSONDecoder().decode(HouseRules.self, from: rulesData)) ?? .default }
        set { rulesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var orderedPlayers: [Player] { players.sorted { $0.orderIndex < $1.orderIndex } }
    var orderedActions: [ActionLogEntry] { actions.sorted { $0.orderIndex < $1.orderIndex } }
    var isInProgress: Bool { endedAt == nil }
    var isInFinalRound: Bool { finalRoundTriggeredByPlayerID != nil && endedAt == nil }

    var activePlayer: Player? {
        let ordered = orderedPlayers
        guard !ordered.isEmpty else { return nil }
        return ordered[activePlayerIndex % ordered.count]
    }

    var currentRound: Int {
        let ordered = orderedPlayers
        guard !ordered.isEmpty else { return 1 }
        return 1 + orderedActions.filter { $0.kind == .bank || $0.kind == .bust }.count / ordered.count
    }

    init(name: String,
         targetScore: Int,
         rules: HouseRules,
         players: [Player]) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.endedAt = nil
        self.targetScore = targetScore
        self.rulesData = (try? JSONEncoder().encode(rules)) ?? Data()
        self.activePlayerIndex = 0
        self.pendingTurnScore = 0
        self.pendingRollCount = 0
        self.finalRoundTriggeredByPlayerID = nil
        self.finalRoundTurnsRemaining = 0
        self.winnerPlayerID = nil
        self.players = players
    }
}

extension Game {
    static func generateName(on date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let day = formatter.string(from: date)
        let hour = Calendar.current.component(.hour, from: date)
        let suffix: String
        switch hour {
        case 5..<12: suffix = "Morning Roll"
        case 12..<17: suffix = "Afternoon Roll"
        case 17..<22: suffix = "Night Roll"
        default: suffix = "Late Roll"
        }
        return "\(day) \(suffix)"
    }
}
