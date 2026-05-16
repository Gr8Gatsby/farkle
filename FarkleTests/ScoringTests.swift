import XCTest
@testable import Farkle

final class ScoringTests: XCTestCase {
    let rules = HouseRules.default
    var engine: ScoreHelperEngine { ScoreHelperEngine(rules: rules) }

    func test_singleOneScores100() {
        XCTAssertEqual(engine.score(dice: [1]).total, 100)
    }

    func test_singleFiveScores50() {
        XCTAssertEqual(engine.score(dice: [5]).total, 50)
    }

    func test_threeOnesScores1000() {
        XCTAssertEqual(engine.score(dice: [1,1,1]).total, 1000)
    }

    func test_threeOfAKind_face4_scores400() {
        XCTAssertEqual(engine.score(dice: [4,4,4]).total, 400)
    }

    func test_fourOfAKind_doubles() {
        XCTAssertEqual(engine.score(dice: [3,3,3,3]).total, 600)
    }

    func test_fiveOfAKind_quadruples() {
        XCTAssertEqual(engine.score(dice: [2,2,2,2,2]).total, 800)
    }

    func test_sixOfAKind_octuples() {
        XCTAssertEqual(engine.score(dice: [6,6,6,6,6,6]).total, 4800)
    }

    func test_straight_oneThroughSix_scores1500() {
        XCTAssertEqual(engine.score(dice: [1,2,3,4,5,6]).total, 1500)
    }

    func test_straight_disabled_falls_back_to_singles() {
        var r = HouseRules.default
        r.straight = false
        let result = ScoreHelperEngine(rules: r).score(dice: [1,2,3,4,5,6])
        XCTAssertEqual(result.total, 150) // single 1 + single 5
    }

    func test_threePairs_scores1500() {
        XCTAssertEqual(engine.score(dice: [2,2,4,4,6,6]).total, 1500)
    }

    func test_twoTriples_enabled_by_default() {
        // Default rules: two triples = 2,500
        XCTAssertEqual(engine.score(dice: [2,2,2,3,3,3]).total, 2500)
    }

    func test_twoTriples_disabled_falls_back_to_singleTriples() {
        var r = HouseRules.default
        r.twoTriples = false
        // 3 of 2s = 200, 3 of 3s = 300 → 500
        XCTAssertEqual(ScoreHelperEngine(rules: r).score(dice: [2,2,2,3,3,3]).total, 500)
    }

    func test_mixed_threeOnes_andSingleFive() {
        XCTAssertEqual(engine.score(dice: [1,1,1,5]).total, 1050)
    }

    func test_emptyReturnsZero() {
        XCTAssertEqual(engine.score(dice: []).total, 0)
    }

    func test_usesAllDice_flag() {
        XCTAssertTrue(engine.score(dice: [1,1,1,5,5,5]).usesAllDice)
        XCTAssertFalse(engine.score(dice: [1,2,3]).usesAllDice)
    }
}
