import SwiftUI

struct OnboardingView: View {
    var onStart: () -> Void

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Hero dice cluster
                ZStack {
                    DieView(value: 5, size: 68)
                        .rotationEffect(.degrees(-12))
                        .offset(x: -78, y: 22)
                    DieView(value: 1, size: 84)
                        .rotationEffect(.degrees(6))
                        .offset(y: -8)
                    DieView(value: 1, size: 68)
                        .rotationEffect(.degrees(-3))
                        .offset(x: 78, y: 30)
                }
                .frame(height: 130)
                .padding(.bottom, 36)

                Text("Roll, hold,")
                    .font(.display(56))
                    .foregroundStyle(Color.ink) +
                Text("\nrepeat.")
                    .font(.display(56, italic: true))
                    .foregroundStyle(Color.walnut)

                Text("The Farkle scorer for game-night purists. No ads, no fuss — just dice, friends, and a little bit of luck.")
                    .font(.ui(16))
                    .foregroundStyle(Color.ink2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 18)

                Spacer()

                Button(action: onStart) {
                    Text("Start a game")
                }
                .buttonStyle(WalnutButtonStyle(size: .large, fullWidth: true))
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    OnboardingView(onStart: {})
}
