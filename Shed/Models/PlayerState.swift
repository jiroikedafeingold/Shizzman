import Foundation

enum PlayerPhase: String, Codable {
    case hand, faceUp, faceDown
    var label: String {
        switch self { case .hand: "Hand"; case .faceUp: "Table cards"; case .faceDown: "Blind cards" }
    }
}

struct PlayerState: Codable {
    var hand:         [GameCard]
    var faceUp:       [GameCard]
    var faceDown:     [GameCard]
    /// Groupings for the face-up zone. Each element is a slot containing 1–4 same-rank cards.
    var faceUpSlots:  [[GameCard]] = []
    /// Groupings for the hand zone. Each element is a slot containing same-rank cards joined during arrange phase.
    var handSlots:    [[GameCard]] = []

    var isEmpty: Bool { hand.isEmpty && faceUp.isEmpty && faceDown.isEmpty }

    var phase: PlayerPhase {
        if !hand.isEmpty    { return .hand     }
        if !faceUp.isEmpty  { return .faceUp   }
        return .faceDown
    }

    var activeCards: [GameCard] {
        switch phase {
        case .hand:     return hand
        case .faceUp:   return faceUp
        case .faceDown: return faceDown
        }
    }

    var totalCards: Int { hand.count + faceUp.count + faceDown.count }

    /// Initialise one slot per face-up card. Call after dealing or rearranging.
    mutating func initFaceUpSlots() {
        faceUpSlots = faceUp.map { [$0] }
        sortFaceUpSlots()
    }

    /// Sort slots ascending by rank of the representative card.
    mutating func sortFaceUpSlots() {
        faceUpSlots.sort { ($0.first?.rank ?? 0) < ($1.first?.rank ?? 0) }
    }

    /// All cards in the same slot as the given face-up card.
    func faceUpSlotGroup(for card: GameCard) -> [GameCard] {
        faceUpSlots.first { $0.contains { $0.id == card.id } } ?? [card]
    }

    /// Initialise one slot per hand card. Call after dealing.
    mutating func initHandSlots() {
        handSlots = hand.map { [$0] }
        sortHandSlots()
    }

    /// Sort hand slots ascending by rank.
    mutating func sortHandSlots() {
        handSlots.sort { ($0.first?.rank ?? 0) < ($1.first?.rank ?? 0) }
    }

    /// All cards in the same hand slot as the given card.
    func handSlotGroup(for card: GameCard) -> [GameCard] {
        handSlots.first { $0.contains { $0.id == card.id } } ?? [card]
    }

    // Remove a card from whichever zone it's in (keeps faceUpSlots and handSlots in sync)
    mutating func removeCard(_ card: GameCard) {
        hand.removeAll     { $0.id == card.id }
        faceUp.removeAll   { $0.id == card.id }
        faceDown.removeAll { $0.id == card.id }
        for i in faceUpSlots.indices {
            faceUpSlots[i].removeAll { $0.id == card.id }
        }
        faceUpSlots.removeAll { $0.isEmpty }
        for i in handSlots.indices {
            handSlots[i].removeAll { $0.id == card.id }
        }
        handSlots.removeAll { $0.isEmpty }
    }

    // Remove multiple cards (multi-rank play)
    mutating func removeCards(_ cards: [GameCard]) { cards.forEach { removeCard($0) } }

    // Add cards to hand as individual slots
    mutating func addToHand(_ cards: [GameCard]) {
        hand.append(contentsOf: cards)
        handSlots.append(contentsOf: cards.map { [$0] })
        sortHandSlots()
    }
}
