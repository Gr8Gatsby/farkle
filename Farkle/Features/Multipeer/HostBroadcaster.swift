import SwiftUI

/// Convenience wrapper that pushes a fresh `GameSnapshot` to a `FarkleNetSession`
/// whenever the live `Game` mutates. Attach via the `.hostBroadcaster(game:session:)`
/// modifier on any view that owns Active Game / Final Round controls.
struct HostBroadcasterModifier: ViewModifier {
    let game: Game
    let session: FarkleNetSession

    func body(content: Content) -> some View {
        content
            .onChange(of: snapshotFingerprint) { _, _ in
                broadcastIfHosting()
            }
            .onAppear { broadcastIfHosting() }
    }

    /// A composite fingerprint of every field viewers care about. Equality on
    /// this string tells SwiftUI when to re-broadcast.
    private var snapshotFingerprint: String {
        // `orderedPlayers` is sorted by orderIndex, so a reorder reshuffles the
        // joined string and a new player extends it — both trigger broadcast.
        let playerFingerprint = game.orderedPlayers
            .map { "\($0.id.uuidString):\($0.bankedScore):\($0.name):\($0.avatarIndex)" }
            .joined(separator: "|")
        return [
            String(game.players.count),
            String(game.actions.count),
            String(game.pendingTurnScore),
            String(game.pendingRollCount),
            String(game.activePlayerIndex),
            String(game.finalRoundTurnsRemaining),
            game.endedAt.map { String($0.timeIntervalSince1970) } ?? "-",
            playerFingerprint
        ].joined(separator: "#")
    }

    private func broadcastIfHosting() {
        guard session.role == .host else { return }
        let snapshot = GameSnapshot(
            game: game,
            seq: 0,  // will be overwritten by the session
            roomCode: session.roomCode,
            hostName: session.latestSnapshot?.hostName ?? UIDevice.current.name
        )
        session.broadcast(snapshot: snapshot)
        session.updateAdvertisedPlayerCount(snapshot.players.count, gameName: snapshot.gameName)
    }
}

extension View {
    func hostBroadcaster(game: Game, session: FarkleNetSession) -> some View {
        modifier(HostBroadcasterModifier(game: game, session: session))
    }
}
