import SwiftUI
import SwiftData

struct HomeView: View {
    var onResume: (Game) -> Void
    var onStartNew: (Game) -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Game.createdAt, order: .reverse) private var allGames: [Game]
    @State private var showNewGame = false

    private var inProgress: Game? { allGames.first(where: { $0.isInProgress }) }
    private var completed: [Game] { Array(allGames.filter { !$0.isInProgress }.prefix(5)) }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if let game = inProgress {
                        resumeCard(game: game).padding(.horizontal, 16).padding(.top, 24)
                    }
                    newGameButton.padding(.horizontal, 16).padding(.top, 12)
                    recentGames.padding(.top, 24)
                    Color.clear.frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showNewGame) {
            NewGameView { game in
                showNewGame = false
                onStartNew(game)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(weekdayLine.uppercased())
                .font(.ui(13, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.ink3)
            (
                Text("Fancy a ")
                    .font(.display(44))
                    .foregroundStyle(Color.ink) +
                Text("roll?")
                    .font(.display(44, italic: true))
                    .foregroundStyle(Color.walnut)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    private var weekdayLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        let day = f.string(from: Date())
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"
        return "\(day) \(part)"
    }

    private func resumeCard(game: Game) -> some View {
        Button { onResume(game) } label: {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("GAME IN PROGRESS")
                        .font(.ui(11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color.paper.opacity(0.7))
                    Text(game.name)
                        .font(.display(26))
                        .foregroundStyle(Color.paper)
                    HStack(spacing: -8) {
                        ForEach(Array(game.orderedPlayers.prefix(5).enumerated()), id: \.element.id) { _, p in
                            AvatarView(name: p.name, colorIndex: p.avatarIndex, size: 32)
                                .background(Circle().stroke(Color.felt, lineWidth: 2).padding(-1))
                        }
                        if let active = game.activePlayer {
                            Text("Round \(game.currentRound) · \(active.name)'s turn")
                                .font(.mono(12))
                                .foregroundStyle(Color.paper.opacity(0.85))
                                .padding(.leading, 16)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.felt)

                HStack {
                    Text("Tap to resume")
                        .font(.ui(13))
                        .foregroundStyle(Color.ink2)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.walnutInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.walnut)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.paperSurface)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.ink.opacity(0.10), radius: 18, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var newGameButton: some View {
        Button { showNewGame = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.walnut)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.walnutInk)
                }
                .frame(width: 44, height: 44)
                .shadow(color: Color.walnutShadow, radius: 0, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start a new game")
                        .font(.display(22))
                        .foregroundStyle(Color.ink)
                    Text("Pick players, set rules, and roll.")
                        .font(.ui(12))
                        .foregroundStyle(Color.ink3)
                }
                Spacer()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.walnut.opacity(0.30), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recentGames: some View {
        if !completed.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Recent games").padding(.horizontal, 24)
                VStack(spacing: 10) {
                    ForEach(completed) { game in
                        recentRow(game: game)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func recentRow(game: Game) -> some View {
        let winner = game.orderedPlayers.first(where: { $0.id == game.winnerPlayerID })
        return PaperCard(padding: 14) {
            HStack(spacing: 12) {
                HStack(spacing: -8) {
                    ForEach(Array(game.orderedPlayers.prefix(3).enumerated()), id: \.element.id) { _, p in
                        AvatarView(name: p.name, colorIndex: p.avatarIndex, size: 28)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(winner?.name ?? "Someone") won")
                        .font(.ui(14, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text("\(game.orderedPlayers.count) players · \(relativeDate(game.createdAt))")
                        .font(.ui(12))
                        .foregroundStyle(Color.ink3)
                }
                Spacer()
                MonoScoreText(value: winner?.bankedScore ?? 0, size: 13, weight: .semibold, color: .ink2)
            }
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
