import SwiftUI

/// A single row the user can tap to add a known scoring combo to their pending turn.
/// Stays a reference list (the player still has to recognize their hand) — not a calculator.
struct ScoreSheetEntry: Identifiable, Equatable {
    let id: String
    let face: Int       // the die face this row is about (0 for combos)
    let count: Int      // how many dice form the combo (0 for combos)
    let label: String
    let points: Int
}

enum ScoreSheetSection: String, CaseIterable, Identifiable {
    case singles = "Singles"
    case threeOfAKind = "Three of a kind"
    case ofAKind = "Four / Five / Six of a kind"
    case specials = "Special combos"
    var id: String { rawValue }
}

struct ScoreSheetCatalog {
    let rules: HouseRules

    func entries(in section: ScoreSheetSection) -> [ScoreSheetEntry] {
        switch section {
        case .singles:
            return [
                ScoreSheetEntry(id: "single-1", face: 1, count: 1, label: "Single 1", points: 100),
                ScoreSheetEntry(id: "single-5", face: 5, count: 1, label: "Single 5", points: 50)
            ]
        case .threeOfAKind:
            return (1...6).map { face in
                let pts = face == 1 ? 300 : face * 100
                return ScoreSheetEntry(id: "three-\(face)", face: face, count: 3,
                                       label: "Three \(face)s", points: pts)
            }
        case .ofAKind:
            return [
                ScoreSheetEntry(id: "four-oak", face: 0, count: 4,
                                label: "Four of a kind", points: 1000),
                ScoreSheetEntry(id: "five-oak", face: 0, count: 5,
                                label: "Five of a kind", points: 2000),
                ScoreSheetEntry(id: "six-oak", face: 0, count: 6,
                                label: "Six of a kind", points: 3000)
            ]
        case .specials:
            var out: [ScoreSheetEntry] = []
            if rules.straight {
                out.append(ScoreSheetEntry(id: "straight", face: 0, count: 6,
                                           label: "Straight 1–6", points: 1500))
            }
            if rules.threePair {
                out.append(ScoreSheetEntry(id: "three-pair", face: 0, count: 6,
                                           label: "Three pairs", points: 1500))
            }
            if rules.twoTriples {
                out.append(ScoreSheetEntry(id: "two-triples", face: 0, count: 6,
                                           label: "Two triplets", points: 2500))
            }
            if rules.fourOfAKindWithPair {
                out.append(ScoreSheetEntry(id: "four-pair", face: 0, count: 6,
                                           label: "4 of a kind w/ pair", points: 1500))
            }
            return out
        }
    }
}

struct ScoreHelperSheet: View {
    let rules: HouseRules
    var onAdd: (Int, Bool) -> Void   // (total, usesAllDice for Hot Dice marking)
    var onCancel: () -> Void

    @State private var picks: [ScoreSheetEntry] = []
    @State private var diceUsed: Int = 0  // accumulated dice across picks

    private var catalog: ScoreSheetCatalog { ScoreSheetCatalog(rules: rules) }

    private var total: Int { picks.reduce(0) { $0 + $1.points } }
    private var usesAllDice: Bool { picks.contains(where: { $0.count == 6 }) || diceUsed == 6 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                runningTotal
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                ScrollView {
                    LazyVStack(spacing: 14, pinnedViews: []) {
                        ForEach(ScoreSheetSection.allCases) { section in
                            let entries = catalog.entries(in: section)
                            if !entries.isEmpty {
                                sectionBlock(title: section.rawValue, entries: entries)
                            }
                        }
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)

                footer
            }
            .background(PaperBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .font(.ui(14))
                        .foregroundStyle(Color.ink2)
                }
                ToolbarItem(placement: .principal) {
                    Text("SCORE HELPER")
                        .font(.ui(11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink3)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: subviews

    private var runningTotal: some View {
        VStack(alignment: .leading, spacing: 6) {
            (
                Text("Tap each combo ").font(.display(20)).foregroundStyle(Color.ink) +
                Text("you rolled.").font(.display(20, italic: true)).foregroundStyle(Color.walnut)
            )
            Text("This is a cheat sheet, not a referee — you still have to spot your own hand.")
                .font(.ui(12))
                .foregroundStyle(Color.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionBlock(title: String, entries: [ScoreSheetEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: title).padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    entryRow(entry: entry)
                    if idx < entries.count - 1 {
                        Rectangle().fill(Color.walnut.opacity(0.08))
                            .frame(height: 0.5)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
        }
    }

    private func entryRow(entry: ScoreSheetEntry) -> some View {
        Button {
            pick(entry)
        } label: {
            HStack(spacing: 12) {
                diceGlyph(for: entry)
                    .frame(width: 96, alignment: .leading)
                Text(entry.label)
                    .font(.ui(15, weight: .medium))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("+\(entry.points.formatted())")
                    .font(.mono(15, weight: .bold))
                    .foregroundStyle(Color.walnut)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.walnut.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(TapHighlightButtonStyle())
        .accessibilityLabel("\(entry.label), \(entry.points) points")
    }

    @ViewBuilder
    private func diceGlyph(for entry: ScoreSheetEntry) -> some View {
        if entry.face == 0 {
            HStack(spacing: 2) {
                ForEach(Array(diceFacesForSpecial(entry: entry).enumerated()), id: \.offset) { _, face in
                    DieView(value: face, size: 14)
                }
            }
        } else {
            HStack(spacing: 2) {
                ForEach(0..<entry.count, id: \.self) { _ in
                    DieView(value: entry.face, size: 14)
                }
            }
        }
    }

    private func diceFacesForSpecial(entry: ScoreSheetEntry) -> [Int] {
        switch entry.id {
        case "straight": return [1,2,3,4,5,6]
        case "three-pair": return [2,2,4,4,6,6]
        case "two-triples": return [3,3,3,5,5,5]
        case "four-pair": return [4,4,4,4,6,6]
        case "four-oak": return [4,4,4,4]
        case "five-oak": return [5,5,5,5,5]
        case "six-oak": return [6,6,6,6,6,6]
        default: return []
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.walnut.opacity(0.10)).frame(height: 0.5)
            HStack(spacing: 10) {
                Button {
                    picks.removeAll()
                    diceUsed = 0
                } label: {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(Color.ink)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                        )
                        .font(.ui(14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .opacity(picks.isEmpty ? 0.4 : 1)
                .disabled(picks.isEmpty)

                Button {
                    onAdd(total, usesAllDice)
                } label: {
                    HStack(spacing: 6) {
                        Text("Add")
                        Text("+\(total.formatted())")
                            .font(.mono(15, weight: .bold))
                        Text("to turn")
                    }
                }
                .buttonStyle(WalnutButtonStyle(size: .regular, fullWidth: true))
                .disabled(total == 0)
                .opacity(total == 0 ? 0.5 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(Color.paper.opacity(0.85).background(.ultraThinMaterial))
        }
    }

    private func pick(_ entry: ScoreSheetEntry) {
        picks.append(entry)
        diceUsed = min(6, diceUsed + entry.count)
    }
}

struct TapHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.walnut.opacity(0.08) : Color.clear)
    }
}
