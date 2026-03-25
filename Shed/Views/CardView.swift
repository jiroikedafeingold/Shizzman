import SwiftUI

struct CardView: View {
    let card:        GameCard
    var faceDown:    Bool = false
    var isSelected:  Bool = false
    var isPlayable:  Bool = true
    var size:        CGSize = CGSize(width: Theme.cW, height: Theme.cH)

    var body: some View {
        ZStack {
            if faceDown {
                cardBack
            } else {
                cardFront
            }
        }
        .frame(width: size.width, height: size.height)
        .cShadow()
    }

    // MARK: - Card back

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.rSm)
                .fill(Theme.cardBack)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.rSm)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
            // Pattern
            RoundedRectangle(cornerRadius: Theme.rSm - 2)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                .padding(5)
            Text("♠")
                .font(.system(size: size.width * 0.3))
                .foregroundStyle(Color.white.opacity(0.12))
        }
    }

    // MARK: - Card front

    private var cardFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.rSm)
                .fill(Theme.cardFace)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.rSm)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .overlay(
                    isSelected
                        ? RoundedRectangle(cornerRadius: Theme.rSm).fill(Theme.hint.opacity(0.12))
                        : nil
                )

            // Centered rank + suit
            VStack(spacing: 1) {
                Text(card.displayRank)
                    .font(.system(size: size.width * 0.46, weight: .bold, design: .rounded))
                    .foregroundStyle(card.suit.cardColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(card.suit.symbol)
                    .font(.system(size: size.width * 0.32))
                    .foregroundStyle(card.suit.cardColor)
            }

            // Special badge
            if let sym = card.specialSymbol {
                VStack {
                    Spacer()
                    HStack {
                        Text(sym)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(specialColor))
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
            }
        }
        .opacity(isPlayable ? 1.0 : 0.45)
    }

    private var borderColor: Color {
        if isSelected { return Theme.hint }
        return .black.opacity(0.10)
    }
    private var borderWidth: CGFloat { isSelected ? 2 : 0.5 }
    private var specialColor: Color {
        if card.isReset { return Theme.reset }
        if card.isLow   { return Theme.low }
        if card.isBurn  { return Theme.burn }
        return .clear
    }
}

// MARK: - Small card badge (for AI hand count)

struct CardCountBadge: View {
    let count: Int
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cardBack)
                .frame(width: Theme.cW * 0.7, height: Theme.cH * 0.5)
            Text("\(count)")
                .font(Theme.headline(18))
                .foregroundStyle(Theme.secondary)
        }
        .cShadow()
    }
}
