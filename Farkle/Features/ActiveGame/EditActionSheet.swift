import SwiftUI

/// Edit the amount of a past bank action. Bust actions can't be edited (they're 0
/// by definition) but they can still be undone from the parent sheet.
struct EditActionSheet: View {
    let game: Game
    let action: ActionLogEntry
    var onSave: (Int) -> Void
    var onUndo: () -> Void
    var onCancel: () -> Void
    var session: FarkleNetSession? = nil

    @State private var entry: String = ""

    private var player: Player? {
        game.players.first(where: { $0.id == action.playerID })
    }
    private var value: Int { Int(entry) ?? 0 }
    private var canSave: Bool {
        value > 0 && value != action.amount && action.kind == .bank
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.walnut.opacity(0.25)).frame(width: 40, height: 4)
                .padding(.top, 8)
            Text("EDIT ACTION")
                .font(.ui(10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.ink3)
                .padding(.top, 12)

            if let player {
                HStack(spacing: 10) {
                    AvatarView(name: player.name,
                               colorIndex: player.avatarIndex,
                               size: 36,
                               photoData: session?.photoData(for: player.id))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.name)
                            .font(.ui(15, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        Text(actionDescription)
                            .font(.ui(12))
                            .foregroundStyle(Color.ink3)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            if action.kind == .bank {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("+")
                        .font(.display(28))
                        .foregroundStyle(Color.ink3)
                    Text(value == 0 ? "0" : value.formatted())
                        .font(.display(48))
                        .foregroundStyle(Color.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                keypad
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            } else {
                Text("This action can't be edited, but it can be undone.")
                    .font(.ui(13))
                    .foregroundStyle(Color.ink3)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button("Cancel") { onCancel() }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                    )
                    .font(.ui(14, weight: .semibold))
                Button {
                    onUndo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Undo")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.crimson.opacity(0.10))
                    .foregroundStyle(Color.crimson)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.crimson.opacity(0.25), lineWidth: 1)
                    )
                    .font(.ui(14, weight: .semibold))
                }
                .buttonStyle(.plain)
                if action.kind == .bank {
                    Button {
                        onSave(value)
                    } label: { Text("Save") }
                    .buttonStyle(WalnutButtonStyle(size: .regular, fullWidth: true))
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.45)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .onAppear {
            if action.kind == .bank { entry = String(action.amount) }
        }
    }

    private var actionDescription: String {
        switch action.kind {
        case .bank: return "banked +\(action.amount.formatted())"
        case .bust: return "busted (Farkle)"
        case .startFinalRound: return "triggered final round"
        case .endGame: return "won the game"
        }
    }

    private var keypad: some View {
        let keys = ["1","2","3","4","5","6","7","8","9","0","00","⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(keys, id: \.self) { key in
                Button {
                    switch key {
                    case "⌫": if !entry.isEmpty { entry.removeLast() }
                    default:
                        let candidate = entry + key
                        if let n = Int(candidate), n <= 99_999 {
                            entry = (candidate.hasPrefix("0") && candidate.count > 1)
                                ? String(Int(candidate) ?? 0)
                                : candidate
                        }
                    }
                } label: {
                    Text(key)
                        .font(.mono(22, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.paperSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
