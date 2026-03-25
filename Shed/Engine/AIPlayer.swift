import Foundation

struct AIPlayer {

    // MARK: - Swap phase: choose best 3 cards to put face-up

    static func chooseFaceUp(hand: [GameCard], current faceUp: [GameCard]) -> ([GameCard], [GameCard]) {
        // Combine all 6 cards and pick the 3 best to be face-up
        let all        = hand + faceUp
        let ranked     = all.sorted { strategicValue($0) > strategicValue($1) }
        let newFaceUp  = Array(ranked.prefix(3))
        let newHand    = all.filter { !newFaceUp.contains($0) }
        return (newHand, newFaceUp)
    }

    // MARK: - Choose card(s) to play

    /// Returns the set of cards to play, or nil to pick up the pile.
    static func choosePlay(state: GameState) -> [GameCard]? {
        let cards   = state.ai.activeCards
        let pileTop = state.pileTop
        let lowMode = state.isLowMode

        // Face-down phase: play the first card blindly (handled by ViewModel)
        if state.ai.phase == .faceDown { return nil }

        let playable = GameRules.playableCards(cards, pileTop: pileTop, isLowMode: lowMode)
        guard !playable.isEmpty else { return nil }   // must pick up

        // Group playable cards by rank to find max-set plays
        let byRank = Dictionary(grouping: playable, by: \.rank)

        // Strategy:

        // 1. If a quad is one card away from completing on top of pile, do it
        if let top = pileTop {
            let sameOnPile  = state.pile.filter { $0.rank == top.rank }.count
            if sameOnPile >= 3, let set = byRank[top.rank], !set.isEmpty {
                // Playing any matching cards completes or approaches quad
                return Array(set.prefix(4 - sameOnPile))
            }
        }

        // 2. Burn (10) when pile top is J or higher — save opponent from low cards
        if (pileTop?.rank ?? 0) >= 11, let burns = byRank[10] {
            return burns
        }

        // 3. Play largest available set of lowest-rank non-special card
        let nonSpecial  = byRank.filter { !GameCard(rank: $0.key, suit: .spades).isSpecial }
        if let best = nonSpecial.min(by: { $0.key < $1.key }) {
            return best.value   // play all of that rank
        }

        // 4. Use 2 (reset) to get out of trouble
        if let resets = byRank[2] { return resets }

        // 5. Last resort: burn
        if let burns = byRank[10] { return burns }

        return [playable[0]]
    }

    // MARK: - Strategic card value (higher = better to keep in hand)

    private static func strategicValue(_ card: GameCard) -> Int {
        switch card.rank {
        case 10: return 100   // burn is gold
        case 2:  return 90    // reset is gold
        case 14: return 80    // Ace
        case 13: return 70    // King
        case 12: return 60    // Queen
        case 7:  return 55    // 7 (low mode)
        case 11: return 50    // Jack
        default: return card.rank
        }
    }
}
