import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allGames: [Game]
    @AppStorage("default.targetScore") private var defaultTargetScore = 10000
    @AppStorage("default.rulesData") private var defaultRulesData = Data()
    @AppStorage("settings.diceSound") private var diceSound = true
    @AppStorage("settings.haptics") private var haptics = true
    @AppStorage("settings.celebrations") private var bigCelebrations = true
    @State private var showResetConfirm = false
    @State private var showExportSheet = false
    @State private var showRules = false
    @State private var exportURL: URL?

    private var rules: HouseRules {
        (try? JSONDecoder().decode(HouseRules.self, from: defaultRulesData)) ?? .default
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    section(title: "Game feel") {
                        toggleRow("Dice sound", isOn: $diceSound)
                        divider
                        toggleRow("Haptics", isOn: $haptics)
                        divider
                        toggleRow("Big celebrations", isOn: $bigCelebrations)
                    }

                    section(title: "Default rules") {
                        navRow("Target score", detail: defaultTargetScore.formatted())
                        divider
                        ruleToggleRow("Three pairs = 1,500", keyPath: \.threePair)
                        divider
                        ruleToggleRow("Straight 1–6 = 1,500", keyPath: \.straight)
                        divider
                        ruleToggleRow("Two triples = 2,500", keyPath: \.twoTriples)
                        divider
                        toggleRow("Must open with 500",
                                  isOn: Binding(get: { rules.mustOpenWith == 500 },
                                                set: { v in update { $0.mustOpenWith = v ? 500 : nil } }))
                    }

                    section(title: "Help") {
                        Button {
                            showRules = true
                        } label: {
                            HStack {
                                Text("How to score").font(.ui(15)).foregroundStyle(Color.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.ink3)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                    }

                    section(title: "Data") {
                        Button {
                            export()
                        } label: {
                            HStack {
                                Text("Export game history").font(.ui(15)).foregroundStyle(Color.ink)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Color.ink3)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        divider
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            HStack {
                                Text("Reset all data").font(.ui(15)).foregroundStyle(Color.crimson)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.crimson)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                    }

                    footer
                    Color.clear.frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
        }
        .alert("Reset all data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetAll() }
        } message: {
            Text("This deletes every game and stat permanently. There is no undo.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                RulesView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showRules = false }
                        }
                    }
            }
        }
    }

    private var header: some View {
        Text("Settings")
            .font(.display(38))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title).padding(.horizontal, 24)
            VStack(spacing: 0) { content() }
                .background(Color.paperSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }

    private var divider: some View {
        Rectangle().fill(Color.walnut.opacity(0.10)).frame(height: 0.5).padding(.leading, 16)
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.ui(15)).foregroundStyle(Color.ink)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Color.felt)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func ruleToggleRow(_ label: String, keyPath: WritableKeyPath<HouseRules, Bool>) -> some View {
        toggleRow(label,
                  isOn: Binding(get: { rules[keyPath: keyPath] },
                                set: { v in update { $0[keyPath: keyPath] = v } }))
    }

    private func navRow(_ label: String, detail: String) -> some View {
        HStack {
            Text(label).font(.ui(15)).foregroundStyle(Color.ink)
            Spacer()
            Text(detail).font(.mono(13)).foregroundStyle(Color.ink3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("FARKLE · v1.0 · made with care")
                .font(.mono(11)).tracking(1)
                .foregroundStyle(Color.ink3)
            Text("No ads. Not now, not ever.")
                .font(.ui(11))
                .foregroundStyle(Color.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func update(_ mutate: (inout HouseRules) -> Void) {
        var r = rules
        mutate(&r)
        defaultRulesData = (try? JSONEncoder().encode(r)) ?? defaultRulesData
    }

    private func resetAll() {
        for game in allGames { context.delete(game) }
        try? context.save()
    }

    private func export() {
        let exporter = GameHistoryExporter(games: allGames.filter { !$0.isInProgress })
        if let url = exporter.write() {
            exportURL = url
            showExportSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct GameHistoryExporter {
    let games: [Game]

    func write() -> URL? {
        struct ExportedGame: Encodable {
            let name: String
            let createdAt: Date
            let endedAt: Date?
            let target: Int
            let winner: String?
            let players: [ExportedPlayer]
            let actions: [ExportedAction]
        }
        struct ExportedPlayer: Encodable { let name: String; let bankedScore: Int }
        struct ExportedAction: Encodable { let player: String; let kind: String; let amount: Int; let at: Date }

        let payload = games.map { g -> ExportedGame in
            let winner = g.players.first(where: { $0.id == g.winnerPlayerID })?.name
            return ExportedGame(
                name: g.name,
                createdAt: g.createdAt,
                endedAt: g.endedAt,
                target: g.targetScore,
                winner: winner,
                players: g.orderedPlayers.map { ExportedPlayer(name: $0.name, bankedScore: $0.bankedScore) },
                actions: g.orderedActions.map { entry in
                    let pname = g.players.first(where: { $0.id == entry.playerID })?.name ?? "—"
                    return ExportedAction(player: pname, kind: entry.kindRaw, amount: entry.amount, at: entry.timestamp)
                }
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("farkle-history.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch { return nil }
    }
}
