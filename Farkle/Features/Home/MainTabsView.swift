import SwiftUI
import SwiftData

enum MainTab: Hashable { case play, history, stats, settings }

struct MainTabsView: View {
    var onResume: (Game) -> Void
    var onStartNew: (Game) -> Void
    var onJoinGame: () -> Void

    @State private var selection: MainTab = .play

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .play:
                    HomeView(onResume: onResume, onStartNew: onStartNew, onJoinGame: onJoinGame)
                case .history:
                    HistoryView()
                case .stats:
                    StatsView()
                case .settings:
                    SettingsView()
                }
            }
            FarkleTabBar(selected: $selection)
        }
    }
}

struct FarkleTabBar: View {
    @Binding var selected: MainTab

    var body: some View {
        HStack {
            tab(.play, label: "Play", systemImage: "die.face.5")
            tab(.history, label: "Games", systemImage: "list.bullet")
            tab(.stats, label: "Stats", systemImage: "chart.bar")
            tab(.settings, label: "Settings", systemImage: "gearshape")
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .background(
            Color.paperSurface.opacity(0.92)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.walnut.opacity(0.10))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    @ViewBuilder
    private func tab(_ tab: MainTab, label: String, systemImage: String) -> some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                Text(label)
                    .font(.ui(10, weight: .semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(selected == tab ? Color.walnut : Color.ink3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
