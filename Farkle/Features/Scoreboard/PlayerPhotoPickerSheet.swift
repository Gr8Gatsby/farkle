import SwiftUI
import PhotosUI

/// Lets a joiner attach a photo to their chosen player slot. Uses
/// SwiftUI's PhotosPicker so no permission prompt is required.
struct PlayerPhotoPickerSheet: View {
    let player: PlayerSnapshot
    var currentPhotoData: Data?
    var onSave: (Data?) -> Void
    var onCancel: () -> Void

    @State private var selection: PhotosPickerItem?
    @State private var preview: Data?
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("YOUR PHOTO")
                                .font(.ui(11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Color.gold)
                            (
                                Text("Show up as ").font(.display(28))
                                    .foregroundStyle(Color.ink) +
                                Text("yourself").font(.display(28, italic: true))
                                    .foregroundStyle(Color.walnut)
                            )
                            .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        AvatarView(name: player.name,
                                   colorIndex: player.avatarIndex,
                                   size: 160,
                                   active: true,
                                   photoData: preview ?? currentPhotoData)
                            .padding(.top, 4)

                        Text(player.name)
                            .font(.display(22, italic: true))
                            .foregroundStyle(Color.ink)

                        if let error {
                            Text(error)
                                .font(.ui(12, weight: .semibold))
                                .foregroundStyle(Color.crimson)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }

                        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(preview == nil && currentPhotoData == nil
                                     ? "Pick a photo"
                                     : "Choose a different photo")
                                    .font(.ui(14, weight: .semibold))
                            }
                            .foregroundStyle(Color.walnutInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.walnut)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.walnutShadow, radius: 0, x: 0, y: 3)
                        }
                        .padding(.horizontal, 16)

                        if currentPhotoData != nil || preview != nil {
                            Button(role: .destructive) {
                                preview = nil
                                onSave(nil)
                            } label: {
                                Text("Remove photo")
                                    .font(.ui(13, weight: .semibold))
                                    .foregroundStyle(Color.crimson)
                            }
                        }

                        if loading {
                            ProgressView().controlSize(.regular)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                HStack(spacing: 10) {
                    Button("Skip") { onSave(nil) }
                        .font(.ui(14, weight: .semibold))
                        .foregroundStyle(Color.ink2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.walnut.opacity(0.25), lineWidth: 1.5)
                        )
                    Button {
                        if let data = preview { onSave(data) } else { onSave(currentPhotoData) }
                    } label: { Text("Use this photo") }
                    .buttonStyle(WalnutButtonStyle(size: .regular, fullWidth: true))
                    .disabled(preview == nil && currentPhotoData == nil)
                    .opacity((preview == nil && currentPhotoData == nil) ? 0.4 : 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(PaperBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .font(.ui(14, weight: .semibold))
                        .foregroundStyle(Color.ink2)
                }
                ToolbarItem(placement: .principal) {
                    Text("PHOTO")
                        .font(.ui(11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink3)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: selection) { _, newItem in
            guard let newItem else { return }
            Task { await load(item: newItem) }
        }
    }

    @MainActor
    private func load(item: PhotosPickerItem) async {
        loading = true
        defer { loading = false }
        do {
            guard let raw = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: raw) else {
                error = "Couldn't read that photo."
                return
            }
            guard let compressed = PhotoBytes.compressedAvatar(from: image) else {
                error = "Couldn't fit that photo. Try another."
                return
            }
            preview = compressed
            error = nil
        } catch {
            self.error = "Couldn't load that photo."
        }
    }
}
