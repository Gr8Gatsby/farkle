import SwiftUI
import SwiftData

struct NewGameDraftPlayer: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var avatarIndex: Int
}

struct NewGameView: View {
    var onStart: (Game) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("default.targetScore") private var defaultTargetScore = 10000
    @AppStorage("default.rulesData") private var defaultRulesData = Data()

    @State private var players: [NewGameDraftPlayer] = [
        NewGameDraftPlayer(name: "", avatarIndex: 0),
        NewGameDraftPlayer(name: "", avatarIndex: 1)
    ]
    @State private var targetScore = 10000
    @State private var rules: HouseRules = .default
    @State private var showCustomTarget = false
    @State private var customTarget = "10000"

    private var validPlayerCount: Int {
        players.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    private var canStart: Bool { validPlayerCount >= 2 }

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        (
                            Text("Who's ").font(.display(38)).foregroundStyle(Color.ink) +
                            Text("playing?").font(.display(38, italic: true)).foregroundStyle(Color.walnut)
                        )
                        .padding(.top, 8)

                        playerList
                        targetSection
                        rulesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                bottomCTA
            }
        }
        .onAppear {
            targetScore = defaultTargetScore
            if let decoded = try? JSONDecoder().decode(HouseRules.self, from: defaultRulesData) {
                rules = decoded
            }
        }
        .alert("Custom target", isPresented: $showCustomTarget) {
            TextField("Target score", text: $customTarget)
                .keyboardType(.numberPad)
            Button("Set") {
                if let n = Int(customTarget), n >= 1000, n <= 50000 {
                    targetScore = (n / 500) * 500
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Between 1,000 and 50,000, in steps of 500.")
        }
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.ui(14))
                .foregroundStyle(Color.ink2)
            Spacer()
            Text("STEP 1 OF 1")
                .font(.ui(12))
                .tracking(1)
                .foregroundStyle(Color.ink3)
            Spacer()
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var playerList: some View {
        VStack(spacing: 8) {
            ForEach($players) { $player in
                playerRow(player: $player)
            }
            if players.count < 8 {
                Button {
                    let idx = players.count
                    players.append(NewGameDraftPlayer(name: "", avatarIndex: idx))
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.walnut.opacity(0.08))
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.ink2)
                        }
                        .frame(width: 36, height: 36)
                        Text("Add player")
                            .font(.ui(14, weight: .medium))
                            .foregroundStyle(Color.ink2)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.walnut.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func playerRow(player: Binding<NewGameDraftPlayer>) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    Rectangle().fill(Color.walnut.opacity(0.3))
                        .frame(width: 16, height: 1)
                }
            }
            AvatarView(name: player.wrappedValue.name.isEmpty ? "?" : player.wrappedValue.name,
                       colorIndex: player.wrappedValue.avatarIndex,
                       size: 36)
            TextField("Player name", text: player.name)
                .font(.ui(17, weight: .medium))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.words)
            if players.count > 2 {
                Button {
                    players.removeAll { $0.id == player.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ink3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.walnut.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Target score")
            HStack(spacing: 8) {
                ForEach([5000, 10000, 15000], id: \.self) { value in
                    targetChip(value: value)
                }
                Button {
                    customTarget = String(targetScore)
                    showCustomTarget = true
                } label: {
                    Text(![5000, 10000, 15000].contains(targetScore) ? "\(targetScore.formatted())" : "Custom")
                        .font(.mono(14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(![5000, 10000, 15000].contains(targetScore) ? Color.walnut : Color.paperSurface)
                        .foregroundStyle(![5000, 10000, 15000].contains(targetScore) ? Color.walnutInk : Color.ink2)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.15), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func targetChip(value: Int) -> some View {
        let selected = targetScore == value
        return Button {
            targetScore = value
        } label: {
            Text(value.formatted())
                .font(.mono(16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(selected ? Color.walnut : Color.paperSurface)
                .foregroundStyle(selected ? Color.walnutInk : Color.ink)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.walnut.opacity(selected ? 0 : 0.15), lineWidth: 0.5)
                )
                .shadow(color: selected ? Color.walnutShadow : .clear, radius: 0, x: 0, y: selected ? 2 : 0)
        }
        .buttonStyle(.plain)
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "House rules")
            VStack(spacing: 0) {
                ruleToggle("Three pairs = 1,500", isOn: $rules.threePair)
                ruleSeparator
                ruleToggle("Straight 1–6 = 1,500", isOn: $rules.straight)
                ruleSeparator
                ruleToggle("Two triples = 2,500", isOn: $rules.twoTriples)
                ruleSeparator
                ruleToggle("Must open with 500",
                           isOn: Binding(
                            get: { rules.mustOpenWith == 500 },
                            set: { rules.mustOpenWith = $0 ? 500 : nil }
                           ))
            }
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
        }
    }

    private func ruleToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.ui(15))
                .foregroundStyle(Color.ink)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.felt)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var ruleSeparator: some View {
        Rectangle().fill(Color.walnut.opacity(0.10)).frame(height: 0.5).padding(.leading, 16)
    }

    private var bottomCTA: some View {
        VStack {
            Button {
                startGame()
            } label: {
                Text("Pass the dice →")
            }
            .buttonStyle(WalnutButtonStyle(size: .large, fullWidth: true))
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 30)
        .background(
            Color.paperSurface.opacity(0.7)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.walnut.opacity(0.10)).frame(height: 0.5), alignment: .top)
        )
    }

    private func startGame() {
        let valid = players.enumerated().compactMap { idx, draft -> Player? in
            let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return Player(name: String(name.prefix(20)),
                          avatarIndex: draft.avatarIndex,
                          orderIndex: idx)
        }
        guard valid.count >= 2 else { return }
        let game = Game(name: Game.generateName(),
                        targetScore: targetScore,
                        rules: rules,
                        players: valid)
        context.insert(game)
        try? context.save()

        defaultTargetScore = targetScore
        if let data = try? JSONEncoder().encode(rules) { defaultRulesData = data }

        onStart(game)
    }
}
