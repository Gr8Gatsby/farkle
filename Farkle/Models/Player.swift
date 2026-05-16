import Foundation
import SwiftData

@Model
final class Player {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarIndex: Int
    var orderIndex: Int
    var bankedScore: Int
    var hotDiceCount: Int
    var farkleCount: Int

    init(name: String, avatarIndex: Int, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.avatarIndex = avatarIndex
        self.orderIndex = orderIndex
        self.bankedScore = 0
        self.hotDiceCount = 0
        self.farkleCount = 0
    }
}
