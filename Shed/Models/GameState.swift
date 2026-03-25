import Foundation

enum Turn: Codable { case player, ai }

enum GamePhase: Codable, Equatable {
    case swap           // player arranges face-up cards
    case playing        // main game
    case gameOver(winner: Turn)
}

struct GameState: Codable {
    var deck:       [GameCard]      // draw pile
    var pile:       [GameCard]      // discard pile (last = top)
    var player:     PlayerState
    var ai:         PlayerState
    var turn:              Turn
    var isLowMode:         Bool            // after 7: must play ≤7
    var phase:             GamePhase
    var playerHasUsedDig:  Bool = false    // one-time dig mechanic

    var pileTop: GameCard? { pile.last }
    var pileIsEmpty: Bool { pile.isEmpty }

    // Status label for the pile
    var pileLabel: String {
        guard let top = pileTop else { return "Play anything" }
        if isLowMode  { return "Play ≤ 7" }
        if top.isReset { return "Play anything" }
        return "Play ≥ \(top.displayRank)"
    }

    // Check if the top 4 cards on the pile are the same rank (quad burn)
    var isQuadOnTop: Bool {
        guard pile.count >= 4 else { return false }
        let top4 = pile.suffix(4)
        return Set(top4.map(\.rank)).count == 1
    }

    static func new() -> GameState {
        var deck = GameCard.fullDeck()
        // Deal: 3 face-down, 3 face-up, 3 hand for each player
        func deal(_ n: Int) -> [GameCard] { (0..<n).map { _ in deck.removeFirst() } }

        let pfd = deal(3); let pfu = deal(3); let ph = deal(3)
        let afd = deal(3); let afu = deal(3); let ah = deal(3)

        var player = PlayerState(hand: ph,  faceUp: pfu, faceDown: pfd)
        player.initFaceUpSlots()
        player.initHandSlots()
        var ai     = PlayerState(hand: ah,  faceUp: afu, faceDown: afd)
        ai.initFaceUpSlots()

        return GameState(
            deck:      deck,
            pile:      [],
            player:    player,
            ai:        ai,
            turn:      .player,
            isLowMode: false,
            phase:     .swap
        )
    }
}
