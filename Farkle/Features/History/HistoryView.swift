import SwiftUI
import SwiftData

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All games"
    case fourPlus = "4+ players"
    case thisMonth = "This month"
    var id: String { rawValue }
}

struct HistoryView: View {
    @Query(sort: \Game.createdAt, order: .reverse) private var games: [Game]
    @State private var filter: HistoryFilter = .all

    private var filtered: [Game] {
        let completed = games.filter { !$0.isInProgress }
        switch filter {
        case .all: return completed
        case .fourPlus: return completed.filter { $0.orderedPlayers.count >= 4 }
        case .thisMonth:
            let cal = Calendar.current
            return completed.filter {
                cal.isDate($0.createdAt, equalTo: Date(), toGranularity: .month)
            }
        }
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    filters
                    list
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            (
                Text("The ").font(.display(38)).foregroundStyle(Color.ink) +
                Text("ledger").font(.display(38, italic: true)).foregroundStyle(Color.walnut)
            )
            let total = games.filter { !$0.isInProgress }.count
            Text("\(total) game\(total == 1 ? "" : "s")")
                .font(.ui(13))
                .foregroundStyle(Color.ink3)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(HistoryFilter.allCases) { f in
                    let selected = filter == f
                    Button {
                        filter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.ui(12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selected ? Color.walnut : Color.paperSurface)
                            .foregroundStyle(selected ? Color.walnutInk : Color.ink2)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.walnut.opacity(selected ? 0 : 0.15), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    private var list: some View {
        VStack(spacing: 10) {
            if filtered.isEmpty {
                emptyState
            } else {
                ForEach(filtered) { game in
                    row(game: game)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 100)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "die.face.5")
                .font(.system(size: 36))
                .foregroundStyle(Color.walnut.opacity(0.5))
            Text("No games yet")
                .font(.display(20, italic: true))
                .foregroundStyle(Color.ink)
            Text("Played games will show up here.")
                .font(.ui(13))
                .foregroundStyle(Color.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func row(game: Game) -> some View {
        let winner = game.orderedPlayers.first(where: { $0.id == game.winnerPlayerID })
        return PaperCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(game.name)
                        .font(.display(19, italic: true))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text(dateLabel(game.createdAt))
                        .font(.mono(11))
                        .foregroundStyle(Color.ink3)
                }
                HStack {
                    HStack(spacing: -8) {
                        ForEach(Array(game.orderedPlayers.prefix(4).enumerated()), id: \.element.id) { _, p in
                            AvatarView(name: p.name, colorIndex: p.avatarIndex, size: 24)
                        }
                        if game.orderedPlayers.count > 4 {
                            Text("+\(game.orderedPlayers.count - 4)")
                                .font(.mono(11))
                                .foregroundStyle(Color.ink3)
                                .padding(.leading, 4)
                        }
                    }
                    Spacer()
                    Text("\(roundsPlayed(game)) rounds · \(duration(game))")
                        .font(.ui(12))
                        .foregroundStyle(Color.ink3)
                }
                .padding(.top, 8)

                HStack {
                    Circle().fill(Color.gold).frame(width: 6, height: 6)
                    Text("\(winner?.name ?? "—") won with")
                        .font(.ui(13))
                        .foregroundStyle(Color.ink2)
                    Spacer()
                    Text((winner?.bankedScore ?? 0).formatted())
                        .font(.mono(14, weight: .bold))
                        .foregroundStyle(Color.ink)
                }
                .padding(.top, 10)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.gold.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 10)
            }
            .padding(16)
        }
    }

    private func dateLabel(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    private func roundsPlayed(_ game: Game) -> Int {
        max(1, game.orderedActions.filter { $0.kind == .bank || $0.kind == .bust }.count / max(1, game.orderedPlayers.count))
    }

    private func duration(_ game: Game) -> String {
        guard let end = game.endedAt else { return "—" }
        let s = end.timeIntervalSince(game.createdAt)
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
