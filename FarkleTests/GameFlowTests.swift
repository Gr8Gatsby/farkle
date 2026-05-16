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

    func test_targetHit_doesNotGiveTriggerAnotherTurn() {
        let game = makeGame(target: 1000, playerNames: ["Maya", "Jules", "Theo"])
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(1000)
        engine.bank()  // Maya triggers final round
        XCTAssertEqual(game.activePlayer?.name, "Jules", "After trigger, the next seat is up — not Maya again.")
        XCTAssertEqual(game.finalRoundTurnsRemaining, 2)
        XCTAssertFalse(game.finalRoundAnnouncementShown, "Announcement should be pending")
    }

    func test_finalRoundAnnouncement_canBeDismissed() {
        let game = makeGame(target: 1000)
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(1000)
        engine.bank()
        XCTAssertFalse(game.finalRoundAnnouncementShown)
        engine.markFinalRoundAnnouncementShown()
        XCTAssertTrue(game.finalRoundAnnouncementShown)
    }

    func test_scoreToBeat_reflectsLeadingTotal() {
        let game = makeGame(target: 1000, playerNames: ["Maya", "Jules"])
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(1000)
        engine.bank()  // Maya → 1000, triggers
        XCTAssertEqual(game.scoreToBeat, 1000)
        // Jules takes her final turn and overtakes
        engine.addToPending(1200)
        engine.bank()
        // Game ends; scoreToBeat is nil after endedAt set
        XCTAssertNotNil(game.endedAt)
        XCTAssertEqual(game.winnerPlayerID, game.orderedPlayers[1].id) // Jules wins
    }

    func test_setActionAmount_editsPastBank() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500)
        engine.bank()
        engine.addToPending(600)  // above must-open-with-500
        engine.bank()
        // Maya = 500, Jules = 600. Edit Maya's bank up to 800.
        let mayaBankID = game.orderedActions.first(where: { $0.kind == .bank })!.id
        engine.setActionAmount(actionID: mayaBankID, newAmount: 800)
        XCTAssertEqual(game.orderedPlayers[0].bankedScore, 800)
        XCTAssertEqual(game.orderedPlayers[1].bankedScore, 600, "Jules's later bank must remain intact after the edit")
    }

    func test_reorderPlayers_keepsActivePlayerActive() {
        let game = makeGame(playerNames: ["Maya", "Jules", "Theo"])
        let engine = GameEngine(game: game, context: context)
        // Maya banks (active passes to Jules)
        engine.addToPending(500); engine.bank()
        XCTAssertEqual(game.activePlayer?.name, "Jules")
        // Reverse the order; the same physical player should still be active.
        let theoID = game.orderedPlayers[2].id
        let julesID = game.orderedPlayers[1].id
        let mayaID = game.orderedPlayers[0].id
        engine.reorderPlayers(by: [theoID, julesID, mayaID])
        XCTAssertEqual(game.activePlayer?.name, "Jules",
                       "Jules was rolling before; she's still rolling after the shuffle")
    }

    func test_addPlayer_allowedInFirstRound() {
        let game = makeGame(playerNames: ["Maya", "Jules"])
        let engine = GameEngine(game: game, context: context)
        XCTAssertTrue(game.canAddPlayer)
        let added = engine.addPlayer(name: "Theo")
        XCTAssertNotNil(added)
        XCTAssertEqual(game.orderedPlayers.last?.name, "Theo")
    }

    func test_addPlayer_blocked_afterFirstRound() {
        let game = makeGame(playerNames: ["Maya", "Jules"])
        let engine = GameEngine(game: game, context: context)
        // Both players take a turn (first round complete).
        engine.addToPending(500); engine.bank()
        engine.addToPending(500); engine.bank()
        XCTAssertFalse(game.canAddPlayer, "First round complete — no more new players")
        XCTAssertNil(engine.addPlayer(name: "Theo"))
    }

    func test_addPlayer_allowedWhenLastSeatYetToRoll() {
        let game = makeGame(playerNames: ["Maya", "Jules"])
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500); engine.bank()  // Maya done; Jules still to roll
        XCTAssertTrue(game.canAddPlayer)
    }

    func test_setActionAmount_refusesBustEdit() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(400)
        engine.bust()
        let bustID = game.orderedActions.first(where: { $0.kind == .bust })!.id
        let didEdit = engine.setActionAmount(actionID: bustID, newAmount: 200)
        XCTAssertFalse(didEdit)
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
