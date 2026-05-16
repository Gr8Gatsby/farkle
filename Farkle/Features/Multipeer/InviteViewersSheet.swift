import SwiftUI

struct InviteViewersSheet: View {
    @Bindable var session: FarkleNetSession
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("LIVE SCOREBOARD")
                                .font(.ui(11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Color.gold)
                            (
                                Text("Share the ").font(.display(30))
                                    .foregroundStyle(Color.ink) +
                                Text("score sheet").font(.display(30, italic: true))
                                    .foregroundStyle(Color.walnut)
                            )
                            .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        roomCodeCard
                        instructions
                        connectedPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                Button("Done") { onDone() }
                    .buttonStyle(WalnutButtonStyle(size: .large, fullWidth: true))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .background(PaperBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stop") {
                        session.stopHosting()
                        onDone()
                    }
                    .font(.ui(14, weight: .semibold))
                    .foregroundStyle(Color.crimson)
                }
                ToolbarItem(placement: .principal) {
                    Text("INVITE VIEWERS")
                        .font(.ui(11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink3)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var roomCodeCard: some View {
        VStack(spacing: 8) {
            Text("ROOM CODE")
                .font(.ui(11, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(Color.ink3)
            HStack(spacing: 8) {
                ForEach(Array(session.roomCode), id: \.self) { ch in
                    Text(String(ch))
                        .font(.display(54))
                        .foregroundStyle(Color.ink)
                        .frame(width: 56, height: 76)
                        .background(Color.paperSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.18), lineWidth: 0.5)
                        )
                        .shadow(color: Color.ink.opacity(0.08), radius: 6, x: 0, y: 3)
                }
            }
            Text("Friends nearby see this game automatically. The code is a backup for tricky networks.")
                .font(.ui(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink3)
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
        .padding(20)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
        )
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "How to join").padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 12) {
                step(num: 1, text: "On the other phone, open Farkle.")
                step(num: 2, text: "Tap **Join a game** on Home.")
                step(num: 3, text: "Pick this game from the list, or enter the room code.")
            }
            .padding(16)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.walnut.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    private func step(num: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(num)")
                .font(.display(22, italic: true))
                .foregroundStyle(Color.walnut)
                .frame(width: 20, alignment: .leading)
            Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
                .font(.ui(13))
                .foregroundStyle(Color.ink)
        }
    }

    private var connectedPanel: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(connected ? Color.felt : Color.ink3.opacity(0.3))
                    .frame(width: 12, height: 12)
                if connected {
                    Circle().stroke(Color.felt.opacity(0.5), lineWidth: 2)
                        .frame(width: 18, height: 18)
                        .scaleEffect(animating ? 1.5 : 1)
                        .opacity(animating ? 0 : 0.6)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: animating)
                        .onAppear { animating = true }
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(connected
                     ? "\(session.connectedPeerCount) viewer\(session.connectedPeerCount == 1 ? "" : "s") connected"
                     : "Waiting for viewers…")
                    .font(.ui(14, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text("Keep this app open during the game.")
                    .font(.ui(11))
                    .foregroundStyle(Color.ink3)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.walnut.opacity(0.08), lineWidth: 0.5)
        )
    }

    @State private var animating = false
    private var connected: Bool { session.connectedPeerCount > 0 }
}
