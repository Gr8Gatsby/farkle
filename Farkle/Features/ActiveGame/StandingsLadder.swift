import SwiftUI
import UIKit

struct StandingsLadder: View {
    let game: Game
    var session: FarkleNetSession? = nil
    var onEdit: (() -> Void)? = nil
    /// Commit a new roll order (player IDs, first to last). Enables in-place
    /// drag-to-reorder when provided.
    var onReorder: (([UUID]) -> Void)? = nil
    /// True while a card is lifted. The parent uses this to throw up a
    /// full-screen tap-catcher; setting it false from outside cancels the drag.
    var isReordering: Binding<Bool> = .constant(false)

    // Drag-reorder state.
    @State private var rowFrames: [UUID: CGRect] = [:]   // measured in "standings" space
    @State private var liveOrder: [UUID] = []
    @State private var draggingID: UUID?
    @State private var dragStartIndex: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var pickupCenterY: CGFloat = 0        // dragged row center at pickup

    private var canReorder: Bool {
        onReorder != nil && game.orderedPlayers.count > 1 && game.endedAt == nil
    }

    /// Order to render: the live (being-dragged) order, otherwise turn order.
    private var renderIDs: [UUID] {
        if draggingID != nil, !liveOrder.isEmpty { return liveOrder }
        return game.orderedPlayers.map(\.id)
    }

    private func player(_ id: UUID) -> Player? {
        game.players.first(where: { $0.id == id })
    }

    private func isActive(_ id: UUID) -> Bool {
        id == game.activePlayer?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
                .padding(.horizontal, 4)

            rowsCard

            if canReorder {
                Text(draggingID == nil
                     ? "Press & hold a player to reorder"
                     : "Drag to a new spot, or tap away to cancel")
                    .font(.ui(10, weight: draggingID == nil ? .regular : .semibold))
                    .foregroundStyle(draggingID == nil ? Color.ink3 : Color.walnut)
                    .padding(.horizontal, 6)
                    .padding(.top, 1)
                    .animation(.easeInOut(duration: 0.2), value: draggingID)
            }
        }
        .coordinateSpace(name: "standings")
        // The lifted card is drawn on top of (and outside) the card's rounded
        // clip, so its shadow and scale aren't cut off.
        .overlay(alignment: .topLeading) { floatingCard }
        .onChange(of: game.orderedPlayers.map(\.id)) { _, newOrder in
            if draggingID == nil { liveOrder = newOrder }
        }
        // Parent cleared the flag (a tap landed off the card) → drop the pickup.
        .onChange(of: isReordering.wrappedValue) { _, active in
            if !active { cancelDrag() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            SectionLabel(text: "Standings")
            Spacer()
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Edit players")
                            .font(.ui(12, weight: .semibold))
                            .tracking(0.3)
                    }
                    .foregroundStyle(Color.walnut)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.walnut.opacity(0.10))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.walnut.opacity(0.18), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit players")
            }
        }
    }

    // MARK: - The unified standings card

    private var rowsCard: some View {
        let ordered = renderIDs.compactMap(player)
        let ranks = scoreRanks(players: game.orderedPlayers)
        return VStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.element.id) { idx, player in
                let rank = ranks[player.id] ?? (idx + 1)
                rowContainer(player: player, rank: rank, isLast: idx == ordered.count - 1)
            }
        }
        .onPreferenceChange(RowFrameKey.self) { rowFrames = $0 }
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
        )
    }

    // MARK: - In-list row (becomes a drop slot while it's the one being dragged)

    @ViewBuilder
    private func rowContainer(player: Player, rank: Int, isLast: Bool) -> some View {
        let isDragging = player.id == draggingID
        let dimmed = draggingID != nil && !isDragging
        VStack(spacing: 0) {
            ZStack {
                playerRow(player: player, rank: rank)
                    .opacity(isDragging ? 0 : 1)   // hidden; the floating card stands in
                if isDragging {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gold.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.gold.opacity(0.7),
                                              style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .transition(.opacity)
                }
            }
            if !isLast {
                Rectangle().fill(Color.walnut.opacity(0.08)).frame(height: 0.5)
                    .opacity(isDragging ? 0 : 1)
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: RowFrameKey.self,
                                       value: [player.id: proxy.frame(in: .named("standings"))])
            }
        )
        .opacity(dimmed ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.2), value: dimmed)
        // Make the WHOLE row draggable. Inactive rows have a clear background,
        // so without this only the name/avatar/score (the actual content) would
        // accept the press — the active row only felt different because its
        // walnut fill already made the full row hit-testable.
        .contentShape(Rectangle())
        .gesture(reorderGesture(for: player.id))
    }

    // MARK: - Floating lifted card

    @ViewBuilder
    private var floatingCard: some View {
        if let id = draggingID, let frame = rowFrames[id], let p = player(id) {
            let rank = scoreRanks(players: game.orderedPlayers)[id] ?? 1
            let centerY = pickupCenterY + dragTranslation
            liftedRow(player: p, rank: rank)
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: centerY - frame.height / 2)
                .allowsHitTesting(false)
        }
    }

    private func liftedRow(player: Player, rank: Int) -> some View {
        playerRow(player: player, rank: rank)
            .background(isActive(player.id) ? Color.walnut : Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gold, lineWidth: 2)
            )
            .scaleEffect(1.05)
            .shadow(color: Color.black.opacity(0.32), radius: 20, x: 0, y: 14)
            .shadow(color: Color.walnutShadow.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    // MARK: - Reorder gesture

    private func reorderGesture(for id: UUID) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(coordinateSpace: .named("standings")))
            .onChanged { value in
                switch value {
                case .first(true):
                    beginDrag(id)
                case .second(true, let drag?):
                    updateDrag(translation: drag.translation.height)
                default:
                    break
                }
            }
            .onEnded { _ in endDrag() }
    }

    private func beginDrag(_ id: UUID) {
        guard canReorder, draggingID == nil else { return }
        let ids = game.orderedPlayers.map(\.id)
        liveOrder = ids
        dragStartIndex = ids.firstIndex(of: id)
        pickupCenterY = rowFrames[id]?.midY ?? 0
        dragTranslation = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            draggingID = id
        }
        isReordering.wrappedValue = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func updateDrag(translation: CGFloat) {
        guard let start = dragStartIndex, let id = draggingID else { return }
        dragTranslation = translation
        let unit = reorderUnitHeight()
        let delta = Int((translation / unit).rounded())
        let target = min(max(0, start + delta), max(0, liveOrder.count - 1))
        if let current = liveOrder.firstIndex(of: id), current != target {
            var ids = game.orderedPlayers.map(\.id)
            ids.removeAll { $0 == id }
            ids.insert(id, at: target)
            withAnimation(.easeInOut(duration: 0.18)) { liveOrder = ids }
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func endDrag() {
        guard draggingID != nil else { return }
        if !liveOrder.isEmpty, liveOrder != game.orderedPlayers.map(\.id) {
            onReorder?(liveOrder)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            draggingID = nil
            dragStartIndex = nil
            dragTranslation = 0
        }
        isReordering.wrappedValue = false
    }

    /// Drop the lifted card back where it started without committing a change.
    private func cancelDrag() {
        guard draggingID != nil else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            draggingID = nil
            dragStartIndex = nil
            dragTranslation = 0
            liveOrder = game.orderedPlayers.map(\.id)
        }
        isReordering.wrappedValue = false
    }

    /// One "slot" of travel. Uses the shortest measured row (the inactive rows),
    /// so crossings feel consistent even though the active row is taller.
    private func reorderUnitHeight() -> CGFloat {
        let measured = rowFrames.values.map(\.height).filter { $0 > 0 }
        return max(40, measured.min() ?? 56)
    }

    // MARK: - Unified player row

    private func playerRow(player: Player, rank: Int) -> some View {
        let active = isActive(player.id)
        let pct = min(1.0, Double(player.bankedScore) / Double(max(1, game.targetScore)))

        let avatarSize: CGFloat = active ? 44 : 28
        let vPad: CGFloat = active ? 14 : 10
        let nameColor = active ? Color.walnutInk : Color.ink
        let scoreColor = active ? Color.walnutInk : Color.ink
        let bgColor = active ? Color.walnut : Color.clear
        let barFill = active ? Color.gold : Color.walnut

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    AvatarView(name: player.name,
                               colorIndex: player.avatarIndex,
                               size: avatarSize,
                               active: active,
                               photoData: session?.photoData(for: player.id))
                        .opacity(active ? 0 : 1)
                    Image(systemName: "dice.fill")
                        .font(.system(size: avatarSize * 0.55, weight: .semibold))
                        .foregroundStyle(Color.gold)
                        .frame(width: avatarSize, height: avatarSize)
                        .opacity(active ? 1 : 0)
                }
                .frame(width: avatarSize, height: avatarSize)

                Text(player.name)
                    .font(active ? .display(26, italic: true) : .ui(15, weight: .medium))
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer()

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.walnut.opacity(0.12)).frame(width: 50, height: 3)
                    Capsule()
                        .fill(barFill)
                        .frame(width: 50 * pct, height: 3)
                }

                MonoScoreText(value: player.bankedScore,
                              size: active ? 24 : 15,
                              weight: .bold,
                              color: scoreColor)
                    .frame(minWidth: 40, alignment: .trailing)

                rankBadge(rank, active: active)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, vPad)
            .background(bgColor)

            if active {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.gold)
                        .frame(width: proxy.size.width * pct, height: 3)
                }
                .frame(height: 3)
                .background(Color.walnut.opacity(0.15))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: active)
    }

    // MARK: - Helpers

    private func scoreRanks(players: [Player]) -> [UUID: Int] {
        let sorted = players.sorted { $0.bankedScore > $1.bankedScore }
        var ranks: [UUID: Int] = [:]
        for (i, p) in sorted.enumerated() {
            if i > 0, sorted[i - 1].bankedScore == p.bankedScore {
                ranks[p.id] = ranks[sorted[i - 1].id]!
            } else {
                ranks[p.id] = i + 1
            }
        }
        return ranks
    }

    private func rankBadge(_ rank: Int, active: Bool) -> some View {
        Text(ordinal(rank))
            .font(.mono(10, weight: .bold))
            .foregroundStyle(active
                             ? Color.walnutInk.opacity(0.8)
                             : (rank == 1 ? Color.walnut : Color.ink3))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(active
                        ? Color.walnutInk.opacity(0.12)
                        : (rank == 1 ? Color.gold.opacity(0.25) : Color.walnut.opacity(0.08)))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}

private struct RowFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
