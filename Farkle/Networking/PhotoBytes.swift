import UIKit

/// Resizes a `UIImage` down to a square avatar suitable for the network and
/// returns its JPEG bytes. Returns `nil` if the image can't be compressed below
/// `PlayerPhoto.maxJPEGBytes`.
enum PhotoBytes {
    static func compressedAvatar(from image: UIImage) -> Data? {
        let size = PlayerPhoto.targetSize
        let resized = image.aspectFillSquare(side: size)
        var quality: CGFloat = 0.85
        while quality > 0.2 {
            if let data = resized.jpegData(compressionQuality: quality),
               data.count <= PlayerPhoto.maxJPEGBytes {
                return data
            }
            quality -= 0.15
        }
        return resized.jpegData(compressionQuality: 0.4)
    }
}

extension UIImage {
    /// Square crop + resize that keeps the centre of the image (good for portraits).
    func aspectFillSquare(side: CGFloat) -> UIImage {
        let scale = max(side / self.size.width, side / self.size.height)
        let newSize = CGSize(width: self.size.width * scale,
                             height: self.size.height * scale)
        let origin = CGPoint(x: (side - newSize.width) / 2,
                             y: (side - newSize.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            self.draw(in: CGRect(origin: origin, size: newSize))
        }
    }
}
