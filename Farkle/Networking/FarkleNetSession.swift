import Foundation
import MultipeerConnectivity
import Observation
import UIKit

// Bonjour service type: lowercase, letters/digits/hyphens, ≤15 chars.
private let kServiceType = "farkle-game"

/// Lightweight MultipeerConnectivity wrapper used by both host (advertising) and
/// joiner (browsing). Host broadcasts `GameSnapshot` payloads on the reliable
/// channel; joiners decode the most recent.
@MainActor
@Observable
final class FarkleNetSession: NSObject {
    enum Role { case idle, host, joiner }
    enum JoinState { case browsing, connecting, connected, disconnected, hostEnded }

    // MARK: observable state
    private(set) var role: Role = .idle
    private(set) var roomCode: String = ""
    private(set) var connectedPeerCount: Int = 0
    private(set) var availableHosts: [DiscoveredHost] = []
    private(set) var latestSnapshot: GameSnapshot?
    private(set) var joinState: JoinState = .browsing

    // MARK: internal
    private let myPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var lastSentSeq: Int = 0

    /// On the host: accumulated player claims (photos) from connected viewers,
    /// keyed by player UUID. Merged into every outgoing snapshot.
    private(set) var playerClaims: [UUID: PlayerClaim] = [:]

    /// Resolve a player's avatar photo. Hosts read from local claims; joiners
    /// fall back to whatever's in the latest snapshot.
    func photoData(for playerID: UUID) -> Data? {
        if role == .host {
            return playerClaims[playerID]?.photoJPEG
        }
        return latestSnapshot?.photoData(for: playerID)
    }

    override init() {
        let name = UIDevice.current.name
        let trimmed = String(name.prefix(63))
        self.myPeerID = MCPeerID(displayName: trimmed.isEmpty ? "Farkle player" : trimmed)
        super.init()
    }

    // MARK: host

    func startHosting(initialSnapshot: GameSnapshot) {
        role = .host
        roomCode = initialSnapshot.roomCode
        lastSentSeq = 0
        latestSnapshot = initialSnapshot

        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let info: [String: String] = [
            "code": initialSnapshot.roomCode,
            "game": initialSnapshot.gameName,
            "players": String(initialSnapshot.players.count),
            "host": initialSnapshot.hostName
        ]
        let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: info, serviceType: kServiceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        broadcast(snapshot: initialSnapshot)
    }

    func updateAdvertisedPlayerCount(_ count: Int, gameName: String) {
        guard role == .host else { return }
        advertiser?.stopAdvertisingPeer()
        let info: [String: String] = [
            "code": roomCode,
            "game": gameName,
            "players": String(count),
            "host": (latestSnapshot?.hostName ?? myPeerID.displayName)
        ]
        let next = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: info, serviceType: kServiceType)
        next.delegate = self
        next.startAdvertisingPeer()
        advertiser = next
    }

    func broadcast(snapshot: GameSnapshot) {
        var snap = snapshot
        snap.playerClaims = Array(playerClaims.values)
        lastSentSeq += 1
        snap.seq = lastSentSeq
        latestSnapshot = snap
        guard role == .host, let session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(MultipeerMessage.snapshot(snap))
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            // Silent: viewers will resync on next change.
        }
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session?.disconnect()
        session = nil
        role = .idle
        connectedPeerCount = 0
        latestSnapshot = nil
    }

    // MARK: joiner

    func startBrowsing() {
        role = .joiner
        joinState = .browsing
        availableHosts = []

        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: kServiceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    func connect(to host: DiscoveredHost) {
        joinState = .connecting
        browser?.invitePeer(host.peerID, to: session!, withContext: nil, timeout: 15)
    }

    func connectByCode(_ code: String) -> Bool {
        guard let match = availableHosts.first(where: { $0.roomCode == code }) else {
            return false
        }
        connect(to: match)
        return true
    }

    /// Joiner: send a player-identity claim (with optional photo) to the host.
    func sendClaim(_ claim: PlayerClaim) {
        guard role == .joiner, let session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(MultipeerMessage.claim(claim))
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            // Silent — the joiner's UI keeps the photo locally regardless.
        }
    }

    func leaveSession() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        role = .idle
        availableHosts = []
        joinState = .disconnected
        latestSnapshot = nil
    }
}

// MARK: - Discovered host

struct DiscoveredHost: Identifiable, Equatable {
    let peerID: MCPeerID
    let hostName: String
    let gameName: String
    let playerCount: Int
    let roomCode: String

    var id: MCPeerID { peerID }
}

// MARK: - MCSession delegate

extension FarkleNetSession: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.connectedPeerCount = session.connectedPeers.count
            switch state {
            case .connected:
                if self.role == .host, let snap = self.latestSnapshot {
                    // Catch the new peer up with the current state.
                    if let data = try? JSONEncoder().encode(MultipeerMessage.snapshot(snap)) {
                        try? session.send(data, toPeers: [peerID], with: .reliable)
                    }
                }
                if self.role == .joiner { self.joinState = .connected }
            case .notConnected:
                if self.role == .joiner, self.joinState == .connected {
                    self.joinState = .hostEnded
                }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(MultipeerMessage.self, from: data) else { return }
        Task { @MainActor in
            switch message {
            case .snapshot(let snap):
                if let current = self.latestSnapshot, snap.seq <= current.seq, current.gameID == snap.gameID {
                    return  // stale
                }
                self.latestSnapshot = snap
            case .claim(let claim):
                guard self.role == .host else { return }
                self.playerClaims[claim.playerID] = claim
                if let current = self.latestSnapshot {
                    // Re-broadcast so every viewer gets the new claim merged in.
                    self.broadcast(snapshot: current)
                }
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser delegate (host)

extension FarkleNetSession: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // MVP: auto-accept any viewer who finds us.
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - Browser delegate (joiner)

extension FarkleNetSession: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let host = DiscoveredHost(
            peerID: peerID,
            hostName: info?["host"] ?? peerID.displayName,
            gameName: info?["game"] ?? "Farkle game",
            playerCount: Int(info?["players"] ?? "0") ?? 0,
            roomCode: info?["code"] ?? ""
        )
        Task { @MainActor in
            if !self.availableHosts.contains(where: { $0.peerID == peerID }) {
                self.availableHosts.append(host)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.availableHosts.removeAll(where: { $0.peerID == peerID })
        }
    }
}

