import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Game.createdAt, order: .reverse) private var games: [Game]
    @AppStorage("stats.primaryPlayerName") private var primaryName: String = ""
    @State private var showPicker = false

    private var completedGames: [Game] { games.filter { !$0.isInProgress } }

    private var allPlayerNames: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for g in completedGames {
            for p in g.orderedPlayers where !seen.contains(p.name) {
                seen.insert(p.name)
                out.append(p.name)
            }
        }
        return out
    }

    private var stats: PlayerStats {
        guard !primaryName.isEmpty else { return PlayerStats.empty }
        return PlayerStats.compute(for: primaryName, in: completedGames)
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(spacing: 0) {
                    profile
                    if primaryName.isEmpty {
                        ChoosePlayerPrompt(allNames: allPlayerNames) { primaryName = $0 }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                    } else {
                        statGrid
                        sparkline
                    }
                    Color.clear.frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
        }
        .confirmationDialog("Choose primary player", isPresented: $showPicker, titleVisibility: .visible) {
            ForEach(allPlayerNames, id: \.self) { name in
                Button(name) { primaryName = name }
            }
            if !primaryName.isEmpty {
                Button("Clear", role: .destructive) { primaryName = "" }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var profile: some View {
        VStack(spacing: 8) {
            AvatarView(name: primaryName.isEmpty ? "?" : primaryName,
                       colorIndex: 0, size: 88, active: !primaryName.isEmpty)
            Text(primaryName.isEmpty ? "No player selected" : primaryName)
                .font(.display(36))
                .foregroundStyle(Color.ink)
            Button(primaryName.isEmpty ? "Choose primary player" : "Change player") {
                showPicker = true
            }
            .font(.ui(12, weight: .semibold))
            .foregroundStyle(Color.walnut)
        }
        .padding(.top, 54)
    }

    private var statGrid: some View {
        VStack(spacing: 0) {
            let entries: [(String, String)] = [
                ("\(stats.gamesPlayed)", "Games"),
                ("\(stats.wins)", "Wins"),
                ("\(stats.winRatePercent)%", "Win rate"),
                ("\(stats.avgTurn)", "Avg turn"),
                ("\(stats.hotDice)", "Hot dice"),
                ("\(stats.farkles)", "Farkles")
            ]
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in statCell(entries[i]).overlayDivider(i < 2) }
                }
                Rectangle().fill(Color.walnut.opacity(0.10)).frame(height: 0.5)
                HStack(spacing: 0) {
                    ForEach(3..<6, id: \.self) { i in statCell(entries[i]).overlayDivider(i < 5) }
                }
            }
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private func statCell(_ entry: (String, String)) -> some View {
        VStack(spacing: 4) {
            Text(entry.0).font(.display(28)).foregroundStyle(Color.ink)
            Text(entry.1.uppercased()).font(.ui(10, weight: .semibold)).tracking(1.2).foregroundStyle(Color.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var sparkline: some View {
        let history = stats.recentAvgTurns
        if history.count >= 2 {
            PaperCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionLabel(text: "Avg turn · last \(history.count)")
                        Spacer()
                        if let trend = stats.trendPercent {
                            Text("\(trend >= 0 ? "↑" : "↓") \(abs(trend))%")
                                .font(.mono(11, weight: .semibold))
                                .foregroundStyle(trend >= 0 ? Color.felt : Color.crimson)
                        }
                    }
                    GeometryReader { proxy in
                        let w = proxy.size.width
                        let h: CGFloat = 60
                        let maxV = CGFloat(history.max() ?? 1)
                        let pts: [CGPoint] = history.enumerated().map { idx, v in
                            CGPoint(
                                x: w * CGFloat(idx) / CGFloat(max(1, history.count - 1)),
                                y: h - CGFloat(v) / maxV * (h - 10) - 5
                            )
                        }
                        ZStack {
                            // area
                            Path { p in
                                guard let first = pts.first else { return }
                                p.move(to: first)
                                for pt in pts.dropFirst() { p.addLine(to: pt) }
                                p.addLine(to: CGPoint(x: w, y: h))
                                p.addLine(to: CGPoint(x: 0, y: h))
                                p.closeSubpath()
                            }
                            .fill(LinearGradient(colors: [Color.walnut.opacity(0.25), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                            // line
                            Path { p in
                                guard let first = pts.first else { return }
                                p.move(to: first)
                                for pt in pts.dropFirst() { p.addLine(to: pt) }
                            }
                            .stroke(Color.walnut, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            if let last = pts.last {
                                Circle().fill(Color.walnut)
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(Color.paperSurface, lineWidth: 2))
                                    .position(last)
                            }
                        }
                    }
                    .frame(height: 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

struct ChoosePlayerPrompt: View {
    let allNames: [String]
    var onChoose: (String) -> Void

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Whose stats?")
                    .font(.display(20, italic: true))
                    .foregroundStyle(Color.ink)
                Text("Pick a player to see their per-game stats. You can change this any time.")
                    .font(.ui(13))
                    .foregroundStyle(Color.ink2)
                if allNames.isEmpty {
                    Text("Stats will appear after you finish a game.")
                        .font(.ui(12))
                        .foregroundStyle(Color.ink3)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(allNames, id: \.self) { name in
                            Button(name) { onChoose(name) }
                                .buttonStyle(ChipButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct PlayerStats {
    var gamesPlayed: Int
    var wins: Int
    var winRatePercent: Int
    var avgTurn: Int
    var hotDice: Int
    var farkles: Int
    var recentAvgTurns: [Int]
    var trendPercent: Int?

    static let empty = PlayerStats(gamesPlayed: 0, wins: 0, winRatePercent: 0,
                                   avgTurn: 0, hotDice: 0, farkles: 0,
                                   recentAvgTurns: [], trendPercent: nil)

    static func compute(for name: String, in games: [Game]) -> PlayerStats {
        var played = 0
        var wins = 0
        var bankAmounts: [Int] = []
        var hot = 0
        var farkleCount = 0
        var perGameAvg: [Int] = []

        for game in games.reversed() {  // chronological
            guard let player = game.orderedPlayers.first(where: { $0.name == name }) else { continue }
            played += 1
            if game.winnerPlayerID == player.id { wins += 1 }
            hot += player.hotDiceCount
            farkleCount += player.farkleCount
            let banks = game.orderedActions.filter { $0.playerID == player.id && $0.kind == .bank }
            bankAmounts.append(contentsOf: banks.map(\.amount))
            if !banks.isEmpty {
                let avg = banks.reduce(0) { $0 + $1.amount } / banks.count
                perGameAvg.append(avg)
            }
        }
        let avgTurn = bankAmounts.isEmpty ? 0 : bankAmounts.reduce(0, +) / bankAmounts.count
        let winPct = played == 0 ? 0 : Int((Double(wins) / Double(played)) * 100)
        let recent = Array(perGameAvg.suffix(10))
        var trend: Int? = nil
        if perGameAvg.count >= 4 {
            let half = max(2, perGameAvg.count / 2)
            let older = Array(perGameAvg.prefix(perGameAvg.count - half))
            let newer = Array(perGameAvg.suffix(half))
            if !older.isEmpty {
                let o = older.reduce(0,+)/older.count
                let n = newer.reduce(0,+)/newer.count
                if o > 0 { trend = Int(((Double(n) - Double(o)) / Double(o)) * 100) }
            }
        }
        return PlayerStats(gamesPlayed: played, wins: wins, winRatePercent: winPct,
                           avgTurn: avgTurn, hotDice: hot, farkles: farkleCount,
                           recentAvgTurns: recent, trendPercent: trend)
    }
}

private extension View {
    @ViewBuilder
    func overlayDivider(_ show: Bool) -> some View {
        if show {
            overlay(
                Rectangle().fill(Color.walnut.opacity(0.10)).frame(width: 0.5),
                alignment: .trailing
            )
        } else {
            self
        }
    }
}
