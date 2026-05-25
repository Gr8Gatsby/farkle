import SwiftUI

struct WalnutButtonStyle: ButtonStyle {
    var size: Size = .regular
    var fullWidth: Bool = false

    enum Size { case regular, large, compact }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(fontSize, weight: .semibold))
            .foregroundStyle(Color.walnutInk)
            .padding(.horizontal, paddingH)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .background(
                ZStack {
                    Color.walnut
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.18), lineWidth: 0.5)
            )
            .shadow(color: Color.walnutShadow.opacity(0.9), radius: 0, x: 0, y: configuration.isPressed ? 0 : 3)
            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var height: CGFloat {
        switch size { case .large: return 56; case .regular: return 48; case .compact: return 40 }
    }
    private var paddingH: CGFloat {
        switch size { case .large: return 28; case .regular: return 22; case .compact: return 16 }
    }
    private var cornerRadius: CGFloat {
        switch size { case .large: return 14; case .regular: return 12; case .compact: return 10 }
    }
    private var fontSize: CGFloat {
        switch size { case .large: return 17; case .regular: return 15; case .compact: return 13 }
    }
}

struct ChipButtonStyle: ButtonStyle {
    var accent: Bool = false
    var size: CGFloat = 48
    var fontSize: CGFloat = 16
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.mono(fontSize, weight: .semibold))
            .foregroundStyle(accent ? Color.walnutInk : Color.ink)
            .padding(.horizontal, 14)
            .frame(minWidth: fullWidth ? nil : 64, maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size)
            .background(
                Group {
                    if accent { Color.walnut } else { Color.paperSurface }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(accent ? Color.clear : Color.walnut.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: accent ? Color.walnutShadow : Color.black.opacity(0.04), radius: 0, x: 0, y: accent ? 2 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PaperCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.walnut.opacity(0.10), lineWidth: 0.5)
            )
            .shadow(color: Color.ink.opacity(0.08), radius: 18, x: 0, y: 6)
            .shadow(color: Color.ink.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}
