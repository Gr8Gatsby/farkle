import Foundation

/// Wire envelope so the host can send `GameSnapshot`s and joiners can send
/// player-identity claims (photos) over the same MCSession channel.
enum MultipeerMessage: Codable {
    case snapshot(GameSnapshot)
    case claim(PlayerClaim)
}

/// A joiner's request to associate themselves with a specific player slot.
/// `photoJPEG` is a resized JPEG (~256×256) so it fits comfortably in one
/// MCSession reliable message.
struct PlayerClaim: Codable, Equatable, Hashable, Identifiable {
    var playerID: UUID
    var photoJPEG: Data?

    var id: UUID { playerID }
}

/// Hard cap to keep snapshot envelopes from blowing past ~256KB even if every
/// player claims a photo. 32KB × 8 players = 256KB worst case.
enum PlayerPhoto {
    static let maxJPEGBytes = 32 * 1024
    static let targetSize: CGFloat = 256
}
