import SwiftUI

struct GameOverView: View {
    @EnvironmentObject private var settings: SettingsStore

    let winner:    Turn
    let time:      String
    let stats:     RoundStats
    let onRematch: () -> Void
    let onHome:    () -> Void

    @State private var appeared  = false
    @State private var symbolScale: CGFloat = 0.3

    var playerWon: Bool { winner == .player }

    var body: some View {
        ZStack {
            settings.felt.ignoresSafeArea()

            // Confetti — only on win
            if playerWon {
                ConfettiView()
            }

            VStack(spacing: 28) {
                // Animated suit symbol
                Text(playerWon ? "♠" : "♣")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(playerWon ? Theme.valid : Theme.burn)
                    .scaleEffect(symbolScale)
                    .opacity(appeared ? 1 : 0)
                    .onAppear {
                        if playerWon {
                            // Bouncy overshoot for win
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                symbolScale = 1.25
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    symbolScale = 1.0
                                }
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.4)) { symbolScale = 1.0 }
                        }
                    }

                VStack(spacing: 8) {
                    Text(playerWon ? L10n.GameOver.youWin : L10n.GameOver.youLose)
                        .font(Theme.display(44))
                        .foregroundStyle(Theme.primary)

                    Text(playerWon ? L10n.GameOver.clearedHand : L10n.GameOver.aiShed)
                        .font(Theme.label(14))
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                }

                // Stats grid
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        statCell(value: time,                     label: L10n.GameOver.time)
                        statDivider()
                        statCell(value: "\(stats.burns)",         label: L10n.GameOver.burns)
                    }
                    Divider().background(Theme.border)
                    HStack(spacing: 0) {
                        statCell(value: "\(stats.longestStreak)", label: L10n.GameOver.bestStreak)
                        statDivider()
                        statCell(value: stats.blindText,          label: L10n.GameOver.blindLuck)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.rMd)
                        .fill(Theme.elevated)
                        .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                            .strokeBorder(Theme.border, lineWidth: 0.5))
                )

                VStack(spacing: 12) {
                    Button(action: onRematch) {
                        Text(L10n.GameOver.playAgain)
                            .font(Theme.headline())
                            .foregroundStyle(Theme.felt)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: Theme.rMd)
                                .fill(playerWon ? Theme.valid : Theme.warn))
                    }
                    .buttonStyle(.plain)

                    Button(action: onHome) {
                        Text(L10n.GameOver.home)
                            .font(Theme.label())
                            .foregroundStyle(Theme.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.rMd)
                                    .fill(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                        .strokeBorder(Theme.border, lineWidth: 0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
            .padding(32)
            .iPadContentWidth()
            .scaleEffect(appeared ? 1 : 0.88)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.72)) { appeared = true }
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.title(22))
                .foregroundStyle(Theme.primary)
            Text(label)
                .font(Theme.caption())
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func statDivider() -> some View {
        Rectangle()
            .fill(Theme.border)
            .frame(width: 0.5)
            .padding(.vertical, 12)
    }
}
