import SwiftUI

struct JoinGameSheet: View {
    @Bindable var session: FarkleNetSession
    var onJoined: () -> Void
    var onCancel: () -> Void

    @State private var mode: Mode = .browse
    @State private var codeEntry: String = ""
    @State private var codeError: String?

    enum Mode: String, CaseIterable { case browse = "Nearby", code = "Code" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                Group {
                    switch mode {
                    case .browse: browsePanel
                    case .code: codePanel
                    }
                }
                Spacer()
                Button("Cancel") {
                    session.leaveSession()
                    onCancel()
                }
                .font(.ui(14, weight: .semibold))
                .foregroundStyle(Color.ink2)
                .padding(.bottom, 20)
            }
            .background(PaperBackground())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("JOIN A GAME")
                        .font(.ui(11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink3)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { session.startBrowsing() }
        .onChange(of: session.joinState) { _, newState in
            if newState == .connected { onJoined() }
        }
    }

    private var modePicker: some View {
        Picker("", selection: $mode) {
            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var browsePanel: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    if session.availableHosts.isEmpty {
                        emptyState
                    } else {
                        ForEach(session.availableHosts) { host in
                            hostRow(host: host)
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .padding(.top, 32)
            Text("Looking for games nearby…")
                .font(.ui(14, weight: .semibold))
                .foregroundStyle(Color.ink)
            Text("Make sure both phones are on the same Wi-Fi (or have Bluetooth on) and the host has tapped Invite viewers.")
                .font(.ui(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink3)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func hostRow(host: DiscoveredHost) -> some View {
        Button {
            session.connect(to: host)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.felt)
                    .frame(width: 36, height: 36)
                    .background(Color.felt.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(host.gameName)
                        .font(.display(19, italic: true))
                        .foregroundStyle(Color.ink)
                    Text("\(host.hostName) · \(host.playerCount) player\(host.playerCount == 1 ? "" : "s")")
                        .font(.ui(12))
                        .foregroundStyle(Color.ink3)
                }
                Spacer()
                Text("JOIN")
                    .font(.mono(11, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.walnut)
                    .foregroundStyle(Color.walnutInk)
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var codePanel: some View {
        VStack(spacing: 16) {
            Text("Enter the 4-digit code shown on the host's phone.")
                .font(.ui(13))
                .foregroundStyle(Color.ink2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 18)

            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { idx in
                    let ch = codeChar(at: idx)
                    Text(ch.isEmpty ? "•" : ch)
                        .font(.display(48))
                        .foregroundStyle(ch.isEmpty ? Color.ink3.opacity(0.4) : Color.ink)
                        .frame(width: 56, height: 76)
                        .background(Color.paperSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.18), lineWidth: 0.5)
                        )
                }
            }

            if let err = codeError {
                Text(err).font(.ui(12, weight: .semibold)).foregroundStyle(Color.crimson)
            }

            keypad
                .padding(.horizontal, 16)
        }
    }

    private func codeChar(at idx: Int) -> String {
        guard idx < codeEntry.count else { return "" }
        let i = codeEntry.index(codeEntry.startIndex, offsetBy: idx)
        return String(codeEntry[i])
    }

    private var keypad: some View {
        let keys = ["1","2","3","4","5","6","7","8","9","","0","⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                if key.isEmpty {
                    Color.clear.frame(height: 50)
                } else {
                    Button {
                        tap(key)
                    } label: {
                        Text(key)
                            .font(.mono(22, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
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

    private func tap(_ key: String) {
        codeError = nil
        if key == "⌫" {
            if !codeEntry.isEmpty { codeEntry.removeLast() }
            return
        }
        if codeEntry.count < 4 { codeEntry.append(key) }
        if codeEntry.count == 4 {
            if !session.connectByCode(codeEntry) {
                codeError = "No game with that code is reachable yet."
            }
        }
    }
}
