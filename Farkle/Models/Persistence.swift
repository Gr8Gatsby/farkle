import Foundation
import SwiftData

enum Persistence {
    static let schema = Schema([Game.self, Player.self, ActionLogEntry.self])

    static let sharedContainer: ModelContainer = {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback to in-memory if persistent store fails (e.g. schema mismatch on dev).
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memConfig])
        }
    }()

    static func previewContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
