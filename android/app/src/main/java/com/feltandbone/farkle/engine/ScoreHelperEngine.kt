package com.feltandbone.farkle.engine

import com.feltandbone.farkle.model.HouseRules

data class ScoreCombo(val label: String, val points: Int)

data class ScoreBreakdown(
    val combos: List<ScoreCombo>,
    val total: Int,
    val usesAllDice: Boolean,
    val leftover: List<Int>,
)

/** Pure scoring evaluator — parity with iOS ScoreHelperEngine. */
class ScoreHelperEngine(private val rules: HouseRules) {

    fun score(rawDice: List<Int>): ScoreBreakdown {
        val dice = rawDice.filter { it in 1..6 }
        if (dice.isEmpty()) {
            return ScoreBreakdown(emptyList(), 0, usesAllDice = false, leftover = emptyList())
        }

        val counts = IntArray(7)
        for (d in dice) counts[d]++
        val remaining = counts.copyOf()
        val combos = mutableListOf<ScoreCombo>()

        if (dice.size == 6) {
            if (rules.straight && (1..6).all { counts[it] == 1 }) {
                return ScoreBreakdown(listOf(ScoreCombo("Straight 1–6", 1500)), 1500, true, emptyList())
            }
            if (rules.threePair && (1..6).count { counts[it] == 2 } == 3) {
                return ScoreBreakdown(listOf(ScoreCombo("Three pairs", 1500)), 1500, true, emptyList())
            }
            if (rules.twoTriples && (1..6).count { counts[it] == 3 } == 2) {
                return ScoreBreakdown(listOf(ScoreCombo("Two triplets", 2500)), 2500, true, emptyList())
            }
            if (rules.fourOfAKindWithPair &&
                (1..6).any { counts[it] == 4 } &&
                (1..6).any { counts[it] == 2 }
            ) {
                return ScoreBreakdown(listOf(ScoreCombo("4 of a kind w/ pair", 1500)), 1500, true, emptyList())
            }
        }

        for (face in 6 downTo 1) {
            val n = remaining[face]
            if (n < 3) continue
            // House rule: three 1s = 300; three N>=2 = N*100; four/five/six = fixed 1000/2000/3000.
            val points: Int
            val label: String
            when (n) {
                6 -> { points = 3000; label = "Six ${face}s" }
                5 -> { points = 2000; label = "Five ${face}s" }
                4 -> { points = 1000; label = "Four ${face}s" }
                else -> {
                    points = if (face == 1) 300 else face * 100
                    label = "Three ${face}s"
                }
            }
            combos.add(ScoreCombo(label, points))
            remaining[face] = 0
        }

        if (remaining[1] > 0) {
            val pts = remaining[1] * 100
            val label = if (remaining[1] == 1) "Single 1" else "${remaining[1]} × 1"
            combos.add(ScoreCombo(label, pts))
            remaining[1] = 0
        }
        if (remaining[5] > 0) {
            val pts = remaining[5] * 50
            val label = if (remaining[5] == 1) "Single 5" else "${remaining[5]} × 5"
            combos.add(ScoreCombo(label, pts))
            remaining[5] = 0
        }

        val leftover = mutableListOf<Int>()
        for (face in 1..6) repeat(remaining[face]) { leftover.add(face) }

        val total = combos.sumOf { it.points }
        return ScoreBreakdown(combos, total, usesAllDice = leftover.isEmpty(), leftover = leftover)
    }
}
