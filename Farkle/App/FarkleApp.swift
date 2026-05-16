import SwiftUI
import SwiftData

@main
struct FarkleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(Persistence.sharedContainer)
    }
}
