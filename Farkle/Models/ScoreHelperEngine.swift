import Foundation

struct ScoreCombo: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let points: Int
}

struct ScoreBreakdown: Equatable {
    var combos: [ScoreCombo]
    var total: Int
    var usesAllDice: Bool
    var leftover: [Int]
}

struct ScoreHelperEngine {
    let rules: HouseRules

    func score(dice: [Int]) -> ScoreBreakdown {
        let dice = dice.filter { (1...6).contains($0) }
        guard !dice.isEmpty else {
            return ScoreBreakdown(combos: [], total: 0, usesAllDice: false, leftover: [])
        }

        var counts = [Int](repeating: 0, count: 7)
        for d in dice { counts[d] += 1 }
        var remaining = counts
        var combos: [ScoreCombo] = []

        if dice.count == 6 {
            if rules.straight, (1...6).allSatisfy({ counts[$0] == 1 }) {
                return ScoreBreakdown(combos: [ScoreCombo(label: "Straight 1–6", points: 1500)],
                                      total: 1500, usesAllDice: true, leftover: [])
            }
            if rules.threePair, (1...6).filter({ counts[$0] == 2 }).count == 3 {
                return ScoreBreakdown(combos: [ScoreCombo(label: "Three pairs", points: 1500)],
                                      total: 1500, usesAllDice: true, leftover: [])
            }
            if rules.twoTriples, (1...6).filter({ counts[$0] == 3 }).count == 2 {
                return ScoreBreakdown(combos: [ScoreCombo(label: "Two triples", points: 2500)],
                                      total: 2500, usesAllDice: true, leftover: [])
            }
        }

        for face in (1...6).reversed() {
            let n = remaining[face]
            guard n >= 3 else { continue }
            let base = face == 1 ? 1000 : face * 100
            // Standard Farkle: four of a kind = 2×, five = 3×, six = 4× (the three-of-a-kind value).
            let multiplier: Int
            let label: String
            switch n {
            case 6: multiplier = 4; label = "Six \(face)s"
            case 5: multiplier = 3; label = "Five \(face)s"
            case 4: multiplier = 2; label = "Four \(face)s"
            default: multiplier = 1; label = "Three \(face)s"
            }
            combos.append(ScoreCombo(label: label, points: base * multiplier))
            remaining[face] = 0
        }

        if remaining[1] > 0 {
            let pts = remaining[1] * 100
            let label = remaining[1] == 1 ? "Single 1" : "\(remaining[1]) × 1"
            combos.append(ScoreCombo(label: label, points: pts))
            remaining[1] = 0
        }
        if remaining[5] > 0 {
            let pts = remaining[5] * 50
            let label = remaining[5] == 1 ? "Single 5" : "\(remaining[5]) × 5"
            combos.append(ScoreCombo(label: label, points: pts))
            remaining[5] = 0
        }

        var leftover: [Int] = []
        for face in 1...6 {
            for _ in 0..<remaining[face] { leftover.append(face) }
        }

        let total = combos.reduce(0) { $0 + $1.points }
        return ScoreBreakdown(combos: combos, total: total, usesAllDice: leftover.isEmpty, leftover: leftover)
    }
}
