import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.modelContext) private var context
    // Include ended games too so the winner celebration can render — the
    // active-game lookup below uses this list, and `inProgressGames` filters
    // it just for the launch-time auto-resume.
    @Query(sort: \Game.createdAt, order: .reverse) private var allGames: [Game]
    @State private var activeGameID: PersistentIdentifier?
    @State private var joinSession = FarkleNetSession()
    @State private var showJoinSheet = false
    @State private var showScoreboard = false

    private var inProgressGames: [Game] {
        allGames.filter { $0.endedAt == nil }
    }

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(onStart: { hasSeenOnboarding = true })
                    .transition(.opacity)
            } else if showScoreboard {
                ScoreboardView(session: joinSession) {
                    showScoreboard = false
                }
                .transition(.opacity)
            } else if let id = activeGameID, let game = allGames.first(where: { $0.persistentModelID == id }) {
                ActiveGameView(game: game, onExit: { newID in
                    activeGameID = newID
                })
                .transition(.opacity)
            } else {
                MainTabsView(
                    onResume: { game in activeGameID = game.persistentModelID },
                    onStartNew: { game in activeGameID = game.persistentModelID },
                    onJoinGame: { showJoinSheet = true }
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.25), value: activeGameID)
        .animation(.easeInOut(duration: 0.25), value: showScoreboard)
        .sheet(isPresented: $showJoinSheet) {
            JoinGameSheet(
                session: joinSession,
                onJoined: {
                    showJoinSheet = false
                    showScoreboard = true
                },
                onCancel: { showJoinSheet = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if activeGameID == nil, let resume = inProgressGames.first {
                activeGameID = resume.persistentModelID
            }
        }
    }
}
