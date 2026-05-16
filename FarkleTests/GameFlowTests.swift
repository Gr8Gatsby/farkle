import XCTest
import SwiftData
@testable import Farkle

@MainActor
final class GameFlowTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Persistence.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    private func makeGame(target: Int = 10000, playerNames: [String] = ["Maya", "Jules"]) -> Game {
        let players = playerNames.enumerated().map { idx, n in
            Player(name: n, avatarIndex: idx, orderIndex: idx)
        }
        let game = Game(name: "Test", targetScore: target, rules: .default, players: players)
        context.insert(game)
        return game
    }

    func test_bankAdvancesActivePlayer() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500)
        engine.bank()
        XCTAssertEqual(game.activePlayer?.name, "Jules")
        XCTAssertEqual(game.orderedPlayers[0].bankedScore, 500)
        XCTAssertEqual(game.pendingTurnScore, 0)
    }

    func test_bustAdvancesAndZeroesPending() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(750)
        engine.bust()
        XCTAssertEqual(game.activePlayer?.name, "Jules")
        XCTAssertEqual(game.orderedPlayers[0].bankedScore, 0)
        XCTAssertEqual(game.orderedPlayers[0].farkleCount, 1)
    }

    func test_mustOpenWith500BlocksLowBank() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(300)
        engine.bank()
        // Should NOT have banked because below 500 with empty banked score
        XCTAssertEqual(game.orderedPlayers[0].bankedScore, 0)
        XCTAssertEqual(game.activePlayer?.name, "Maya")
    }

    func test_targetHitTriggersFinalRound_andEndsAfterOthersPlay() {
        let game = makeGame(target: 1000)
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(1000)
        engine.bank()  // Maya triggers final
        XCTAssertNotNil(game.finalRoundTriggeredByPlayerID)
        XCTAssertEqual(game.finalRoundTurnsRemaining, 1)
        XCTAssertNil(game.endedAt)
        // Jules takes final turn
        engine.addToPending(500)
        engine.bank()
        XCTAssertNotNil(game.endedAt)
        XCTAssertEqual(game.winnerPlayerID, game.orderedPlayers[0].id) // Maya wins
    }

    func test_undoLast_reversesBank() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500)
        engine.bank()
        engine.undoLast()
        XCTAssertEqual(game.orderedPlayers[0].bankedScore, 0)
        XCTAssertEqual(game.activePlayer?.name, "Maya")
        XCTAssertTrue(game.actions.isEmpty)
    }

    func test_undoFromGameOver_restoresActiveGame() {
        let game = makeGame(target: 500)
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500)
        engine.bank()  // Maya hits target
        engine.bust()  // Jules takes final turn and busts → ends
        XCTAssertNotNil(game.endedAt)
        engine.undoLast()  // undo endGame
        // After undoing endGame, the bust+startFinalRound+bank chain may need more undos.
        // The "Wait that's wrong" button on Game Over uses undoLast repeatedly via UI design,
        // but for the spec it must at minimum exit ended state.
        XCTAssertNil(game.endedAt)
    }
}
