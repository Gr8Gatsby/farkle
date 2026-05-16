import SwiftUI

struct AvatarView: View {
    var name: String
    var colorIndex: Int
    var size: CGFloat = 36
    var active: Bool = false

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    var body: some View {
        let colors = AvatarPalette.colors(for: colorIndex)
        Text(initial)
            .font(.display(size * 0.5))
            .foregroundStyle(colors.fg)
            .frame(width: size, height: size)
            .background(Circle().fill(colors.bg))
            .overlay(
                Circle()
                    .stroke(active ? colors.bg : Color.clear, lineWidth: 2)
                    .padding(-3)
                    .background(
                        Circle()
                            .stroke(active ? Color.paper : Color.clear, lineWidth: 3)
                            .padding(-3)
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: active ? 8 : 2, x: 0, y: active ? 4 : 1)
    }
}
