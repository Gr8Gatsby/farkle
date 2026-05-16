import SwiftUI

extension Font {
    /// Instrument Serif. Falls back to a serif system font if the bundled TTF isn't loaded.
    static func display(_ size: CGFloat, italic: Bool = false) -> Font {
        let name = italic ? "InstrumentSerif-Italic" : "InstrumentSerif-Regular"
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: .title)
        }
        let base = Font.system(size: size, weight: .regular, design: .serif)
        return italic ? base.italic() : base
    }

    /// IBM Plex Sans for UI body and labels.
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "IBMPlexSans-Bold"
        case .semibold: name = "IBMPlexSans-SemiBold"
        case .medium: name = "IBMPlexSans-Medium"
        default: name = "IBMPlexSans-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: .body)
        }
        return .system(size: size, weight: weight, design: .default)
    }

    /// JetBrains Mono for tabular numbers.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "JetBrainsMono-Bold"
        case .semibold, .medium: name = "JetBrainsMono-Medium"
        default: name = "JetBrainsMono-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: .body).monospacedDigit()
        }
        return .system(size: size, weight: weight, design: .monospaced).monospacedDigit()
    }
}
