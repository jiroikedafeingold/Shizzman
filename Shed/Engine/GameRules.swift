import Foundation

struct GameRules {

    // MARK: - Can a card be played on the current pile?

    static func canPlay(card: GameCard, pileTop: GameCard?, isLowMode: Bool) -> Bool {
        guard let top = pileTop else { return true }   // empty pile: anything goes
        if card.isBurn  { return true }                // 10 always burns
        if card.isReset { return true }                // 2 always resets
        if isLowMode    { return card.rank <= 7 }
        return card.rank >= top.rank
    }

    // Can we play a SET of same-rank cards? Valid if every card in set can be played.
    static func canPlaySet(_ cards: [GameCard], pileTop: GameCard?, isLowMode: Bool) -> Bool {
        guard !cards.isEmpty, Set(cards.map(\.rank)).count == 1 else { return false }
        return canPlay(card: cards[0], pileTop: pileTop, isLowMode: isLowMode)
    }

    static func playableCards(_ cards: [GameCard], pileTop: GameCard?, isLowMode: Bool) -> [GameCard] {
        cards.filter { canPlay(card: $0, pileTop: pileTop, isLowMode: isLowMode) }
    }

    static func hasPlayableCard(_ cards: [GameCard], pileTop: GameCard?, isLowMode: Bool) -> Bool {
        cards.contains { canPlay(card: $0, pileTop: pileTop, isLowMode: isLowMode) }
    }

    // MARK: - Apply a play to game state
    // Returns (burnedPile: Bool, goAgain: Bool)

    @discardableResult
    static func applyPlay(cards: [GameCard], state: inout GameState) -> (burned: Bool, goAgain: Bool) {
        state.pile.append(contentsOf: cards)

        // Check quad burn (4 of same rank on top)
        let burned = state.isQuadOnTop || cards.first!.isBurn
        if burned {
            state.pile = []
            state.isLowMode = false
            return (true, true)    // go again after burn
        }

        state.isLowMode = cards.first!.isLow
        return (false, false)
    }

    // MARK: - Draw up to 3 cards from deck

    static func drawToThree(player: inout PlayerState, deck: inout [GameCard]) {
        while player.hand.count < 3 && !deck.isEmpty {
            player.hand.append(deck.removeFirst())
        }
    }
}
