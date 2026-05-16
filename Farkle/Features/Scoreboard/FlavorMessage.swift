import Foundation

/// Generates one-line announcements ("Maya passed Theo!") from snapshot deltas.
/// Pure function — no view state, easy to test.
struct FlavorMessage: Identifiable, Equatable {
    enum Tone: Equatable { case neutral, positive, negative, drama }

    let id = UUID()
    let text: String
    let tone: Tone
}

enum FlavorMessageMaker {
    /// Compute flavor messages between two consecutive snapshots.
    static func diff(previous: GameSnapshot?, current: GameSnapshot) -> [FlavorMessage] {
        guard let previous else { return [] }
        var out: [FlavorMessage] = []

        // Position changes (banked totals)
        let beforeOrder = previous.players
            .sorted { $0.bankedScore > $1.bankedScore }
            .map(\.id)
        let afterOrder = current.players
            .sorted { $0.bankedScore > $1.bankedScore }
            .map(\.id)
        for (idx, pid) in afterOrder.enumerated() {
            let prevIdx = beforeOrder.firstIndex(of: pid) ?? idx
            if prevIdx > idx, let player = current.players.first(where: { $0.id == pid }) {
                let passedNames = afterOrder[(idx+1)...prevIdx].compactMap { otherID in
                    previous.players.first(where: { $0.id == otherID })?.name
                }
                if let passed = passedNames.first, passedNames.count == 1 {
                    out.append(.init(text: "\(player.name) passed \(passed)!", tone: .positive))
                } else if !passedNames.isEmpty {
                    out.append(.init(text: "\(player.name) jumped \(passedNames.count) spots!", tone: .positive))
                }
            }
        }

        // First Farkle for any player
        for current_p in current.players {
            let prevFarkle = previous.players.first(where: { $0.id == current_p.id })?.farkleCount ?? 0
            if current_p.farkleCount > prevFarkle {
                out.append(.init(text: "Tough break for \(current_p.name).", tone: .negative))
            }
        }

        // Hot dice
        for current_p in current.players {
            let prevHot = previous.players.first(where: { $0.id == current_p.id })?.hotDiceCount ?? 0
            if current_p.hotDiceCount > prevHot {
                out.append(.init(text: "🔥 \(current_p.name) — hot dice!", tone: .drama))
            }
        }

        // Final round triggered
        if previous.finalRoundTriggeredByPlayerID == nil,
           let triggerID = current.finalRoundTriggeredByPlayerID,
           let trigger = current.players.first(where: { $0.id == triggerID }) {
            out.append(.init(text: "\(trigger.name) hit the target. Final round!", tone: .drama))
        }

        // Almost there (within 1000 of target, first time)
        let target = current.targetScore
        for current_p in current.players {
            let prev = previous.players.first(where: { $0.id == current_p.id })?.bankedScore ?? 0
            if current_p.bankedScore > prev,
               current_p.bankedScore >= target - 1000,
               current_p.bankedScore < target,
               prev < target - 1000 {
                out.append(.init(text: "\(current_p.name) is one good roll from \(target.formatted()).", tone: .drama))
            }
        }

        // Win
        if previous.endedAt == nil, current.endedAt != nil,
           let winnerID = current.winnerPlayerID,
           let winner = current.players.first(where: { $0.id == winnerID }) {
            out.append(.init(text: "\(winner.name) wins. 🎉", tone: .drama))
        }

        return out
    }
}
