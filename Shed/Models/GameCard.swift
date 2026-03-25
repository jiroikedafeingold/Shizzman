import SwiftUI

enum Suit: Int, CaseIterable, Codable {
    case spades = 0, hearts = 1, diamonds = 2, clubs = 3

    var symbol: String {
        switch self {
        case .spades: return "♠"; case .hearts: return "♥"
        case .diamonds: return "♦"; case .clubs: return "♣"
        }
    }
    var isRed: Bool { self == .hearts || self == .diamonds }
    var cardColor: Color { isRed ? Color(red:0.82,green:0.08,blue:0.08) : Color(red:0.04,green:0.06,blue:0.10) }
}

struct GameCard: Identifiable, Codable, Equatable, Hashable {
    let id:   UUID
    let rank: Int     // 2–14  (J=11 Q=12 K=13 A=14)
    let suit: Suit

    init(rank: Int, suit: Suit) { id = UUID(); self.rank = rank; self.suit = suit }

    var displayRank: String {
        switch rank { case 11:"J"; case 12:"Q"; case 13:"K"; case 14:"A"; default:"\(rank)" }
    }
    var isReset: Bool { rank == 2  }   // can always play; pile "resets" (anything ≥2 next)
    var isLow:   Bool { rank == 7  }   // next player must play ≤7
    var isBurn:  Bool { rank == 10 }   // burns the pile; go again
    var isSpecial: Bool { isReset || isLow || isBurn }

    var specialSymbol: String? {
        if isReset { return "↺" }; if isLow { return "↓" }; if isBurn { return "✕" }; return nil
    }

    static func fullDeck() -> [GameCard] {
        Suit.allCases.flatMap { suit in (2...14).map { GameCard(rank: $0, suit: suit) } }.shuffled()
    }
}
