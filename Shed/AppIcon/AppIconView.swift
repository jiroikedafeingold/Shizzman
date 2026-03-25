import SwiftUI

// ─────────────────────────────────────────────
// App icon design — screenshot from Preview at
// 1024 × 1024 to use as the App Store icon.
// ─────────────────────────────────────────────

struct AppIconView: View {
    private let cardW: CGFloat = 620
    private let cardH: CGFloat = 880
    private let red = Color(red: 0.82, green: 0.08, blue: 0.08)
    private let burn = Color(red: 0.90, green: 0.34, blue: 0.24)

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.12, blue: 0.09)

            RadialGradient(
                colors: [Color.white.opacity(0.07), Color.clear],
                center: .top, startRadius: 0, endRadius: 600
            )

            // Card
            ZStack {
                RoundedRectangle(cornerRadius: 52)
                    .fill(Color(red: 0.97, green: 0.96, blue: 0.93))
                    .shadow(color: .black.opacity(0.55), radius: 28, x: 0, y: 10)

                // Rank + suit centered
                VStack(spacing: 6) {
                    Text("10")
                        .font(.system(size: cardW * 0.46, weight: .bold, design: .rounded))
                        .foregroundStyle(red)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("♥")
                        .font(.system(size: cardW * 0.32))
                        .foregroundStyle(red)
                }

                // Burn badge — bottom left, like in-game
                VStack {
                    Spacer()
                    HStack {
                        Text("✕")
                            .font(.system(size: cardW * 0.055, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, cardW * 0.028)
                            .padding(.vertical, cardW * 0.014)
                            .background(Capsule().fill(burn))
                        Spacer()
                    }
                    .padding(.horizontal, cardW * 0.07)
                    .padding(.bottom, cardW * 0.07)
                }
            }
            .frame(width: cardW, height: cardH)
        }
        .frame(width: 1024, height: 1024)
        .ignoresSafeArea()
    }
}

#Preview("App Icon 1024×1024") {
    AppIconView()
        .frame(width: 1024, height: 1024)
}
