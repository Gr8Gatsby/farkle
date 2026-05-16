import XCTest
import SwiftData
@testable import Farkle

@MainActor
final class SnapshotTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Persistence.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    private func makeGame(playerNames: [String] = ["Maya","Jules"]) -> Game {
        let players = playerNames.enumerated().map { idx, n in
            Player(name: n, avatarIndex: idx, orderIndex: idx)
        }
        let g = Game(name: "Test", targetScore: 10000, rules: .default, players: players)
        context.insert(g)
        return g
    }

    func test_snapshot_roundtripsThroughJSON() throws {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500); engine.bank()
        engine.addToPending(700); engine.bank()

        let original = GameSnapshot(game: game, seq: 5, roomCode: "1357", hostName: "iPhone of Maya")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_snapshot_includesRecentActions() {
        let game = makeGame()
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(500); engine.bank()
        engine.addToPending(700); engine.bank()
        let snap = GameSnapshot(game: game, seq: 1, roomCode: "1357", hostName: "host")
        XCTAssertEqual(snap.recentActions.count, 2)
        XCTAssertEqual(snap.recentActions.last?.amount, 700)
    }

    func test_finalRoundTrigger_inSnapshot() {
        let game = Game(name: "FR", targetScore: 1000, rules: .default, players: [
            Player(name: "Maya", avatarIndex: 0, orderIndex: 0),
            Player(name: "Jules", avatarIndex: 1, orderIndex: 1)
        ])
        context.insert(game)
        let engine = GameEngine(game: game, context: context)
        engine.addToPending(1000); engine.bank()
        let snap = GameSnapshot(game: game, seq: 1, roomCode: "1357", hostName: "host")
        XCTAssertTrue(snap.isInFinalRound)
        XCTAssertNotNil(snap.finalRoundTriggeredByPlayerID)
        XCTAssertEqual(snap.scoreToBeat, 1000)
    }

    func test_roomCode_format() {
        for _ in 0..<200 {
            let code = RoomCode.generate()
            XCTAssertEqual(code.count, 4)
            XCTAssertTrue(RoomCode.isValid(code))
            XCTAssertFalse(RoomCode.isAmbiguous(code))
        }
    }

    func test_flavorMessage_passingDetected() {
        let before = makeSnapshotWith(scores: [("Maya", 3000), ("Jules", 5000)])
        let after = makeSnapshotWith(scores: [("Maya", 6000), ("Jules", 5000)])
        let msgs = FlavorMessageMaker.diff(previous: before, current: after)
        XCTAssertTrue(msgs.contains(where: { $0.text.contains("Maya passed Jules") }))
    }

    func test_flavorMessage_finalRoundTrigger() {
        var before = makeSnapshotWith(scores: [("Maya", 9000), ("Jules", 5000)])
        before.finalRoundTriggeredByPlayerID = nil
        var after = makeSnapshotWith(scores: [("Maya", 10500), ("Jules", 5000)])
        after.finalRoundTriggeredByPlayerID = before.players[0].id
        let msgs = FlavorMessageMaker.diff(previous: before, current: after)
        XCTAssertTrue(msgs.contains(where: { $0.text.contains("Final round") }))
    }

    // MARK: helper

    private func makeSnapshotWith(scores: [(String, Int)]) -> GameSnapshot {
        let players = scores.enumerated().map { idx, pair in
            PlayerSnapshot(id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", idx+1))")!,
                           name: pair.0,
                           avatarIndex: idx,
                           orderIndex: idx,
                           bankedScore: pair.1,
                           hotDiceCount: 0,
                           farkleCount: 0)
        }
        return GameSnapshot(seq: 1,
                            roomCode: "1357",
                            hostName: "host",
                            gameID: UUID(),
                            gameName: "Test",
                            targetScore: 10000,
                            rules: .default,
                            players: players,
                            activePlayerID: players.first?.id,
                            pendingTurnScore: 0,
                            pendingRollCount: 0,
                            finalRoundTriggeredByPlayerID: nil,
                            finalRoundTurnsRemaining: 0,
                            scoreToBeat: nil,
                            recentActions: [],
                            endedAt: nil,
                            winnerPlayerID: nil)
    }
}
