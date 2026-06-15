package com.feltandbone.farkle

import com.feltandbone.farkle.engine.ScoreHelperEngine
import com.feltandbone.farkle.model.HouseRules
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ScoringTest {
    private val engine = ScoreHelperEngine(HouseRules.DEFAULT)

    @Test fun singleOneScores100() = assertEquals(100, engine.score(listOf(1)).total)

    @Test fun singleFiveScores50() = assertEquals(50, engine.score(listOf(5)).total)

    @Test fun threeOnes_uniformFormula_300() = assertEquals(300, engine.score(listOf(1, 1, 1)).total)

    @Test fun threeOfAKind_face4_scores400() = assertEquals(400, engine.score(listOf(4, 4, 4)).total)

    @Test fun fourOfAKind_fixed_1000() {
        assertEquals(1000, engine.score(listOf(3, 3, 3, 3)).total)
        assertEquals(1000, engine.score(listOf(6, 6, 6, 6)).total)
    }

    @Test fun fiveOfAKind_fixed_2000() = assertEquals(2000, engine.score(listOf(2, 2, 2, 2, 2)).total)

    @Test fun sixOfAKind_fixed_3000() = assertEquals(3000, engine.score(listOf(6, 6, 6, 6, 6, 6)).total)

    @Test fun fourOfAKindWithPair_scores1500() =
        assertEquals(1500, engine.score(listOf(5, 5, 5, 5, 3, 3)).total)

    @Test fun fourOfAKindWithPair_disabled_falls_back() {
        val r = HouseRules.DEFAULT.copy(fourOfAKindWithPair = false)
        assertEquals(1000, ScoreHelperEngine(r).score(listOf(5, 5, 5, 5, 3, 3)).total)
    }

    @Test fun straight_oneThroughSix_scores1500() =
        assertEquals(1500, engine.score(listOf(1, 2, 3, 4, 5, 6)).total)

    @Test fun straight_disabled_falls_back_to_singles() {
        val r = HouseRules.DEFAULT.copy(straight = false)
        assertEquals(150, ScoreHelperEngine(r).score(listOf(1, 2, 3, 4, 5, 6)).total)
    }

    @Test fun threePairs_scores1500() = assertEquals(1500, engine.score(listOf(2, 2, 4, 4, 6, 6)).total)

    @Test fun twoTriples_enabled_by_default() =
        assertEquals(2500, engine.score(listOf(2, 2, 2, 3, 3, 3)).total)

    @Test fun twoTriples_disabled_falls_back_to_singleTriples() {
        val r = HouseRules.DEFAULT.copy(twoTriples = false)
        assertEquals(500, ScoreHelperEngine(r).score(listOf(2, 2, 2, 3, 3, 3)).total)
    }

    @Test fun mixed_threeOnes_andSingleFive() = assertEquals(350, engine.score(listOf(1, 1, 1, 5)).total)

    @Test fun emptyReturnsZero() = assertEquals(0, engine.score(emptyList()).total)

    @Test fun usesAllDice_flag() {
        assertTrue(engine.score(listOf(1, 1, 1, 5, 5, 5)).usesAllDice)
        assertFalse(engine.score(listOf(1, 2, 3)).usesAllDice)
    }
}
