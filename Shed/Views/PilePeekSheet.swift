import SwiftUI

struct PilePeekSheet: View {
    let pile: [GameCard]

    // Pile is ordered bottom→top; show top card first
    private var ordered: [GameCard] { pile.reversed() }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.PilePeek.title)
                        .font(Theme.caption(10))
                        .tracking(3)
                        .foregroundStyle(Theme.tertiary)
                    Text(L10n.PilePeek.subtitle(pile.count))
                        .font(Theme.caption(12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider().background(Theme.border).padding(.horizontal, 20)

            // Cards grid
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: Theme.cW + 8), spacing: 10)],
                    spacing: 12
                ) {
                    ForEach(Array(ordered.enumerated()), id: \.element.id) { index, card in
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                CardView(card: card)
                                if index == 0 {
                                    Text(L10n.PilePeek.top)
                                        .font(Theme.caption(8))
                                        .tracking(1)
                                        .foregroundStyle(Theme.felt)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Theme.valid))
                                        .offset(x: 4, y: -6)
                                }
                            }
                            Text("#\(index + 1)")
                                .font(Theme.caption(9))
                                .foregroundStyle(Theme.tertiary)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}
