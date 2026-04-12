import SwiftUI

struct PileView: View {
    let state:      GameState
    let burnFlash:  Bool
    let deckCount:  Int

    var body: some View {
        HStack(spacing: 28) {
            // Deck
            VStack(spacing: 4) {
                ZStack {
                    if deckCount > 1 {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.cardBack.opacity(0.6))
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .offset(x: -2, y: -2)
                    }
                    if deckCount > 0 {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.cardBack)
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .overlay(RoundedRectangle(cornerRadius: Theme.rSm)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                    } else {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Color.red.opacity(0.12))
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .overlay(RoundedRectangle(cornerRadius: Theme.rSm)
                                .strokeBorder(Color.red.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [4,3])))
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundStyle(Color.red.opacity(0.6))
                            )
                    }
                }
                .cShadow()

                Text("\(deckCount) left")
                    .font(Theme.caption(14))
                    .foregroundStyle(deckCount == 0 ? Color.red.opacity(0.7) : Theme.tertiary)
            }

            // Pile
            VStack(spacing: 12) {
                // Top card(s) stack
                ZStack {
                    if state.pile.count > 2 {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.cardFace.opacity(0.4))
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .offset(x: -4, y: -4)
                    }
                    if state.pile.count > 1 {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.cardFace.opacity(0.7))
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .offset(x: -2, y: -2)
                    }

                    if burnFlash {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.burn.opacity(0.35))
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .overlay(Text("✕").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(Theme.burn))
                            .transition(.opacity)
                    } else if let top = state.pileTop {
                        CardView(card: top)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .id(top.id)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .fill(Theme.surface)
                            .frame(width: Theme.cardW, height: Theme.cardH)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.rSm)
                                    .strokeBorder(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [4,3]))
                            )
                            .overlay(Text("Empty").font(Theme.caption(14)).foregroundStyle(Theme.tertiary))
                    }
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.75), value: state.pileTop?.id)
                .animation(.easeInOut(duration: 0.3), value: burnFlash)

                // Status label
                Text(state.pileLabel.uppercased())
                    .font(Theme.caption(14))
                    .tracking(2)
                    .foregroundStyle(pileStatusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(pileStatusColor.opacity(0.14))
                            .overlay(Capsule().strokeBorder(pileStatusColor.opacity(0.3), lineWidth: 1))
                    )
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.25), value: state.pileLabel)

                Text("\(state.pile.count) card\(state.pile.count == 1 ? "" : "s")")
                    .font(Theme.caption(14))
                    .foregroundStyle(Theme.tertiary)
            }
        }
    }

    private var pileStatusColor: Color {
        if burnFlash         { return Theme.burn  }
        if state.isLowMode   { return Theme.low   }
        if state.pileIsEmpty { return Theme.valid }
        if state.pileTop?.isReset == true { return Theme.valid }
        return Theme.secondary
    }
}
