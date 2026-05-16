import SwiftUI
import SwiftData

/// Mid-game player roster editor: drag to reorder, plus an "Add player" row when
/// the first round hasn't completed yet.
struct EditPlayersSheet: View {
    @Bindable var game: Game
    var onDone: () -> Void
    var session: FarkleNetSession? = nil

    @Environment(\.modelContext) private var context
    @State private var orderedIDs: [UUID] = []
    @State private var newName: String = ""
    @State private var showAddRow: Bool = false
    @FocusState private var nameFocused: Bool

    private var engine: GameEngine { GameEngine(game: game, context: context) }

    private var orderedDraft: [Player] {
        orderedIDs.compactMap { id in game.players.first(where: { $0.id == id }) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(orderedDraft, id: \.id) { player in
                        playerRow(player: player)
                            .listRowBackground(Color.paperSurface)
                    }
                    .onMove { from, to in
                        orderedIDs.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("ROLL ORDER")
                        .font(.ui(11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink3)
                } footer: {
                    Text("Drag to change who rolls next. The current player stays active.")
                        .font(.ui(11))
                        .foregroundStyle(Color.ink3)
                }

                if game.canAddPlayer {
                    Section {
                        if showAddRow {
                            addRow
                                .listRowBackground(Color.paperSurface)
                        } else {
                            Button {
                                showAddRow = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    nameFocused = true
                                }
                            } label: {
                                Label("Add player", systemImage: "person.crop.circle.fill.badge.plus")
                                    .font(.ui(15, weight: .semibold))
                                    .foregroundStyle(Color.walnut)
                            }
                            .listRowBackground(Color.paperSurface)
                        }
                    } footer: {
                        Text("You can add players while the first round is in progress.")
                            .font(.ui(11))
                            .foregroundStyle(Color.ink3)
                    }
                } else if game.endedAt == nil {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color.ink3)
                            Text("New players can only join during the first round.")
                                .font(.ui(12))
                                .foregroundStyle(Color.ink3)
                        }
                        .listRowBackground(Color.paperSurface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDone() }
                        .font(.ui(14))
                        .foregroundStyle(Color.ink2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        engine.reorderPlayers(by: orderedIDs)
                        onDone()
                    }
                    .font(.ui(14, weight: .semibold))
                    .foregroundStyle(Color.walnut)
                }
            }
        }
        .onAppear {
            if orderedIDs.isEmpty {
                orderedIDs = game.orderedPlayers.map(\.id)
            }
        }
    }

    private func playerRow(player: Player) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: player.name,
                       colorIndex: player.avatarIndex,
                       size: 36,
                       photoData: session?.photoData(for: player.id))
            VStack(alignment: .leading, spacing: 1) {
                Text(player.name)
                    .font(.ui(15, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text("\(player.bankedScore.formatted()) banked")
                    .font(.mono(11))
                    .foregroundStyle(Color.ink3)
            }
            Spacer()
            if player.id == game.activePlayer?.id {
                Text("ROLLING")
                    .font(.mono(8, weight: .bold))
                    .tracking(0.6)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.gold)
                    .foregroundStyle(Color.walnut)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            }
        }
        .padding(.vertical, 4)
    }

    private var addRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.walnut)
                .frame(width: 36, height: 36)
                .background(Color.walnut.opacity(0.10))
                .clipShape(Circle())
            TextField("Player name", text: $newName)
                .font(.ui(15))
                .focused($nameFocused)
                .submitLabel(.done)
                .textInputAutocapitalization(.words)
                .onSubmit { addPlayer() }
            Button("Add") { addPlayer() }
                .font(.ui(14, weight: .semibold))
                .foregroundStyle(newName.trimmingCharacters(in: .whitespaces).isEmpty
                                 ? Color.ink3 : Color.walnut)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addPlayer() {
        guard let added = engine.addPlayer(name: newName) else { return }
        orderedIDs.append(added.id)
        newName = ""
        showAddRow = false
        nameFocused = false
    }
}
