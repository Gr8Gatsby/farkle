import SwiftUI
import UIKit
import Contacts
import ContactsUI

/// SwiftUI wrapper around `CNContactPickerViewController`. The system picker
/// runs out-of-process, so it doesn't require Contacts permission — Farkle
/// only receives whatever the user explicitly taps.
struct ContactPhotoPicker: UIViewControllerRepresentable {
    /// Called with the contact's avatar bytes (already resized + JPEG-compressed)
    /// or `nil` if the picked contact has no photo.
    var onPick: (Data?) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // We only need image data — limiting the displayed keys avoids
        // showing fields the user doesn't care about.
        picker.displayedPropertyKeys = [
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey
        ]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (Data?) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (Data?) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let raw = contact.imageData ?? contact.thumbnailImageData
            guard let raw, let uiImage = UIImage(data: raw),
                  let compressed = PhotoBytes.compressedAvatar(from: uiImage) else {
                onPick(nil)
                return
            }
            onPick(compressed)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }
    }
}
