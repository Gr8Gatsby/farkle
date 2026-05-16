import SwiftUI
import UIKit
import Photos

struct GameOverView: View {
    @Bindable var game: Game
    var onUndo: () -> Void
    var onExit: () -> Void
    var onRematch: () -> Void
    var session: FarkleNetSession? = nil

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var saveToast: SaveToast?

    private var winner: Player? {
        game.players.first(where: { $0.id == game.winnerPlayerID })
            ?? game.orderedPlayers.max(by: { $0.bankedScore < $1.bankedScore })
    }

    private var standings: [Player] {
        game.orderedPlayers.sorted { $0.bankedScore > $1.bankedScore }
    }

    private var hasViewers: Bool { (session?.connectedPeerCount ?? 0) > 0 }

    var body: some View {
        ZStack {
            PaperBackground()
            ConfettiView()
                .allowsHitTesting(false)
            // Warm halo behind trophy
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.gold.opacity(0.30), location: 0),
                    .init(color: .clear, location: 0.7)
                ]),
                center: UnitPoint(x: 0.5, y: 0.22),
                startRadius: 0, endRadius: 240
            )
            .allowsHitTesting(false)

            content
            chrome
            if let toast = saveToast { saveToastView(toast).transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: shareItems(image: image))
            }
        }
        .onAppear {
            if shareImage == nil {
                shareImage = WinImageRenderer.image(for: game, session: session)
            }
        }
    }

    // MARK: top chrome

    private var chrome: some View {
        VStack {
            HStack(alignment: .top) {
                connectionChip
                Spacer()
                closeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var connectionChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(hasViewers ? Color.felt : Color.walnut)
                .frame(width: 6, height: 6)
            Text(hasViewers
                 ? "SYNCED · \(session?.connectedPeerCount ?? 0)"
                 : "SAVED LOCALLY")
                .font(.mono(9, weight: .bold))
                .tracking(1)
                .foregroundStyle(hasViewers ? Color.felt : Color.walnut)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill((hasViewers ? Color.felt : Color.walnut).opacity(0.10))
        )
        .overlay(
            Capsule()
                .stroke((hasViewers ? Color.felt : Color.walnut).opacity(0.25), lineWidth: 0.5)
        )
    }

    private var closeButton: some View {
        Button {
            onExit()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ink2)
                .frame(width: 34, height: 34)
                .background(Color.paperSurface)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.walnut.opacity(0.18), lineWidth: 0.5))
                .shadow(color: Color.ink.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close winner screen")
    }

    // MARK: body content

    private var content: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)
            TrophyView(size: 170, ribbon: winnerRibbonText())
                .shadow(color: Color.walnut.opacity(0.20), radius: 24, x: 0, y: 12)

            // Eyebrow + name + score
            VStack(spacing: 4) {
                Text(game.name.uppercased())
                    .font(.ui(11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.ink3)
                if let winner {
                    let firstName = winner.name.split(separator: " ").first.map(String.init) ?? winner.name
                    (
                        Text(firstName).font(.display(44, italic: true))
                            .foregroundStyle(Color.walnut) +
                        Text(" wins.").font(.display(44))
                            .foregroundStyle(Color.ink)
                    )
                    CountUpScore(value: winner.bankedScore, size: 32, color: .walnut)
                        .padding(.top, 2)
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 24)
            .multilineTextAlignment(.center)

            standingsCard
                .padding(.horizontal, 16)
                .padding(.top, 18)

            Button {
                onUndo()
            } label: {
                Text("Wait — that's wrong. Undo last bank.")
                    .font(.ui(12, weight: .semibold))
                    .foregroundStyle(Color.ink3)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            Spacer()
            actionButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
    }

    private func winnerRibbonText() -> String {
        guard let winner else { return "WINNER" }
        let first = winner.name.split(separator: " ").first.map(String.init) ?? winner.name
        return first.uppercased()
    }

    private var standingsCard: some View {
        VStack(spacing: 0) {
            if let winner {
                HStack(spacing: 12) {
                    AvatarView(name: winner.name,
                               colorIndex: winner.avatarIndex,
                               size: 48,
                               active: true,
                               photoData: session?.photoData(for: winner.id))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("1ST PLACE")
                            .font(.ui(10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color.ink3)
                        Text(winner.name)
                            .font(.display(22, italic: true))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer()
                    MonoScoreText(value: winner.bankedScore, size: 18, weight: .bold, color: .walnut)
                }
                Rectangle()
                    .fill(Color.walnut.opacity(0.10))
                    .frame(height: 0.5)
                    .padding(.vertical, 6)
            }
            ForEach(Array(standings.dropFirst().enumerated()), id: \.element.id) { idx, p in
                HStack(spacing: 10) {
                    Text("\(idx + 2)")
                        .font(.display(16, italic: true))
                        .foregroundStyle(Color.ink3)
                        .frame(width: 18, alignment: .leading)
                    AvatarView(name: p.name,
                               colorIndex: p.avatarIndex,
                               size: 22,
                               photoData: session?.photoData(for: p.id))
                    Text(p.name)
                        .font(.ui(13))
                        .foregroundStyle(Color.ink2)
                    Spacer()
                    MonoScoreText(value: p.bankedScore, size: 13, color: .ink2)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.walnut.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.ink.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                share()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                    Text("Share the win")
                        .font(.ui(15, weight: .bold))
                }
                .foregroundStyle(Color.walnutInk)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.walnut)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.walnutShadow, radius: 0, x: 0, y: 3)
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button { saveImage() } label: {
                    Text("Save image")
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.paperSurface)
                        .foregroundStyle(Color.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.15), lineWidth: 0.5)
                        )
                        .font(.ui(13, weight: .semibold))
                }
                .buttonStyle(.plain)
                Button { onRematch() } label: {
                    Text("Rematch")
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.felt)
                        .foregroundStyle(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.feltDeep, radius: 0, x: 0, y: 2)
                        .font(.ui(13, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: actions

    @MainActor
    private func share() {
        if shareImage == nil {
            shareImage = WinImageRenderer.image(for: game, session: session)
        }
        if shareImage != nil { showShareSheet = true }
    }

    private func shareItems(image: UIImage) -> [Any] {
        var items: [Any] = [image]
        if let winner {
            items.append("\(winner.name) won our Farkle game at \(winner.bankedScore.formatted()).")
        }
        return items
    }

    @MainActor
    private func saveImage() {
        let image: UIImage
        if let cached = shareImage {
            image = cached
        } else if let rendered = WinImageRenderer.image(for: game, session: session) {
            shareImage = rendered
            image = rendered
        } else {
            return
        }
        PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        } completionHandler: { ok, _ in
            Task { @MainActor in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    saveToast = ok
                        ? SaveToast(text: "Saved to Photos", success: true)
                        : SaveToast(text: "Couldn't save — check Photos permission in Settings.", success: false)
                }
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                withAnimation(.easeOut(duration: 0.3)) { saveToast = nil }
            }
        }
    }

    private func saveToastView(_ toast: SaveToast) -> some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: toast.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(toast.success ? Color.felt : Color.crimson)
                Text(toast.text)
                    .font(.ui(13, weight: .semibold))
                    .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.paperSurface)
            .clipShape(Capsule())
            .shadow(color: Color.ink.opacity(0.15), radius: 12, x: 0, y: 6)
            .padding(.top, 70)
            Spacer()
        }
    }

    private struct SaveToast: Equatable {
        let text: String
        let success: Bool
    }
}
