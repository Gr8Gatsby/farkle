import SwiftUI

extension Color {
    // Paper / ink
    static let paper = Color(red: 0.953, green: 0.929, blue: 0.878)        // #f3ede0
    static let paper2 = Color(red: 0.922, green: 0.890, blue: 0.824)       // #ebe3d2
    static let paperSurface = Color(red: 0.984, green: 0.969, blue: 0.922) // #fbf7eb
    static let ink = Color(red: 0.165, green: 0.145, blue: 0.125)          // #2a2520
    static let ink2 = Color(red: 0.353, green: 0.310, blue: 0.259)         // #5a4f42
    static let ink3 = Color(red: 0.541, green: 0.502, blue: 0.443)         // #8a8071

    // Walnut
    static let walnut = Color(red: 0.357, green: 0.227, blue: 0.122)       // #5b3a1f
    static let walnutInk = Color(red: 0.969, green: 0.937, blue: 0.871)    // #f7efde
    static let walnutShadow = Color(red: 0.173, green: 0.094, blue: 0.031) // #2c1808

    // Felt
    static let felt = Color(red: 0.176, green: 0.353, blue: 0.278)         // #2d5a47
    static let feltDeep = Color(red: 0.122, green: 0.263, blue: 0.196)     // #1f4332

    // Accents
    static let crimson = Color(red: 0.659, green: 0.204, blue: 0.102)      // #a8341a
    static let gold = Color(red: 0.722, green: 0.541, blue: 0.243)         // #b88a3e
    static let gold2 = Color(red: 0.831, green: 0.659, blue: 0.353)        // #d4a85a

    // Bone (dice)
    static let bone = Color(red: 0.980, green: 0.965, blue: 0.933)         // #faf6ee
    static let bonePip = Color(red: 0.102, green: 0.071, blue: 0.039)
}

enum AvatarPalette {
    static let pairs: [(bg: Color, fg: Color)] = [
        (Color(red: 0.659, green: 0.204, blue: 0.102), Color(red: 0.984, green: 0.898, blue: 0.867)),
        (Color(red: 0.176, green: 0.353, blue: 0.278), Color(red: 0.867, green: 0.910, blue: 0.886)),
        (Color(red: 0.357, green: 0.227, blue: 0.122), Color(red: 0.922, green: 0.851, blue: 0.753)),
        (Color(red: 0.722, green: 0.541, blue: 0.243), Color(red: 0.953, green: 0.902, blue: 0.788)),
        (Color(red: 0.290, green: 0.357, blue: 0.541), Color(red: 0.871, green: 0.886, blue: 0.933)),
        (Color(red: 0.431, green: 0.239, blue: 0.420), Color(red: 0.914, green: 0.867, blue: 0.906)),
        (Color(red: 0.227, green: 0.420, blue: 0.357), Color(red: 0.863, green: 0.918, blue: 0.894)),
        (Color(red: 0.545, green: 0.290, blue: 0.227), Color(red: 0.925, green: 0.851, blue: 0.824)),
    ]

    static func colors(for index: Int) -> (bg: Color, fg: Color) {
        pairs[((index % pairs.count) + pairs.count) % pairs.count]
    }
}
