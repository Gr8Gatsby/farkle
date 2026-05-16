import SwiftUI
import SwiftData

@main
struct FarkleApp: App {
    init() {
        DefaultsMigrator.runIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(Persistence.sharedContainer)
    }
}
