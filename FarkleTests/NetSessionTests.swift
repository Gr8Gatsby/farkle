import XCTest
@testable import Farkle

/// Covers the decision that fixes the "viewers keep getting dropped" report:
/// a session drop should silently reconnect, and only be treated as a real
/// "host ended the game" when the host had already broadcast an ended game.
final class NetSessionTests: XCTestCase {

    func test_transientDrop_reconnects() {
        // Host is still mid-game (no endedAt) — a drop here is a blip, not an end.
        XCTAssertEqual(
            FarkleNetSession.joinStateAfterDrop(hostGameEnded: false),
            .reconnecting
        )
    }

    func test_dropAfterGameEnded_isHostEnded() {
        // The host already told us the game finished, so the drop is expected.
        XCTAssertEqual(
            FarkleNetSession.joinStateAfterDrop(hostGameEnded: true),
            .hostEnded
        )
    }

    func test_reconnecting_isADistinctState() {
        // Regression guard: reconnecting must not collapse into the terminal
        // states, or the viewer would be bounced out again.
        XCTAssertNotEqual(FarkleNetSession.JoinState.reconnecting, .hostEnded)
        XCTAssertNotEqual(FarkleNetSession.JoinState.reconnecting, .disconnected)
        XCTAssertNotEqual(FarkleNetSession.JoinState.reconnecting, .connected)
    }
}
