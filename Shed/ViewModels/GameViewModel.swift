import SwiftUI
import Combine

struct RoundStats {
    var burns:          Int = 0
    var longestStreak:  Int = 0
    var currentStreak:  Int = 0
    var blindFlips:     Int = 0
    var blindSuccesses: Int = 0

    var blindText: String {
        blindFlips == 0 ? "—" : "\(blindSuccesses)/\(blindFlips)"
    }
}

/// Decides when to ask for an App Store rating: after the player's 3rd win, then again
/// at most once per app version and no sooner than 10 wins after the last ask.
/// (StoreKit itself further caps the prompt at three showings a year.)
enum ReviewPrompter {
    private static let winsKey        = "review.wins"
    private static let lastWinsKey    = "review.lastPromptWins"
    private static let lastVersionKey = "review.lastPromptVersion"

    /// Records a win and returns true if now is a good moment to ask for a review.
    static func recordWin() -> Bool {
        let defaults = UserDefaults.standard
        let wins = defaults.integer(forKey: winsKey) + 1
        defaults.set(wins, forKey: winsKey)

        let version  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastWins = defaults.integer(forKey: lastWinsKey)
        let neverAsked = lastWins == 0
        guard wins >= 3,
              neverAsked || (wins - lastWins >= 10 && defaults.string(forKey: lastVersionKey) != version)
        else { return false }

        defaults.set(wins, forKey: lastWinsKey)
        defaults.set(version, forKey: lastVersionKey)
        return true
    }
}

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var state:          GameState = .new()
    @Published private(set) var selectedCards:  Set<UUID> = []
    @Published private(set) var aiThinking:     Bool = false
    @Published private(set) var message:        String = ""
    @Published private(set) var burnFlash:       Bool = false
    @Published private(set) var pickupFlash:     Bool = false
    @Published private(set) var elapsedSecs:     Int = 0
    @Published private(set) var stats:           RoundStats = RoundStats()
    @Published private(set) var blindReveal:     GameCard? = nil  // card shown briefly on failed flip
    @Published private(set) var winningBlindCard: GameCard? = nil // card shown briefly on winning blind flip
    @Published private(set) var wantsReviewRequest: Bool = false // a win made now a good moment to ask for a rating

    // MARK: - Private

    private var timer: AnyCancellable?

    init() { startNewGame() }

    // MARK: - New game

    func startNewGame() {
        stopTimer()
        state         = .new()
        selectedCards = []
        aiThinking    = false
        elapsedSecs   = 0
        stats         = RoundStats()
        message       = L10n.Msg.arrange
        // AI does its swap immediately
        let (newHand, newFaceUp) = AIPlayer.chooseFaceUp(
            hand:    state.ai.hand,
            current: state.ai.faceUp
        )
        state.ai.hand   = newHand
        state.ai.faceUp = newFaceUp
        state.ai.initFaceUpSlots()
    }

    // MARK: - Swap phase

    func swapPlayerCards(handCard: GameCard, faceUpCard: GameCard) {
        guard case .swap = state.phase else { return }
        guard let hi = state.player.hand.firstIndex(of: handCard),
              let fi = state.player.faceUp.firstIndex(of: faceUpCard) else { return }
        state.player.hand[hi]   = faceUpCard
        state.player.faceUp[fi] = handCard
        // Sync slots: replace faceUpCard with handCard in its slot
        for si in state.player.faceUpSlots.indices {
            if let ci = state.player.faceUpSlots[si].firstIndex(where: { $0.id == faceUpCard.id }) {
                state.player.faceUpSlots[si][ci] = handCard
                break
            }
        }
        state.player.sortFaceUpSlots()
        // Sync handSlots: replace handCard with faceUpCard in its slot
        for si in state.player.handSlots.indices {
            if let ci = state.player.handSlots[si].firstIndex(where: { $0.id == handCard.id }) {
                state.player.handSlots[si][ci] = faceUpCard
                break
            }
        }
        state.player.sortHandSlots()
        HapticManager.tap()
    }

    /// Move all cards in the hand slot identified by `handCard` into the face-up slot that contains `tableCard` (same rank required).
    /// Draws from the deck to restore the hand to 3.
    func joinHandSlotToFaceUpSlot(handCard: GameCard, tableCard: GameCard) {
        guard case .swap = state.phase else { return }
        guard handCard.rank == tableCard.rank else { return }
        guard let hsi = state.player.handSlots.firstIndex(where: {
            $0.contains { $0.id == handCard.id }
        }) else { return }
        guard let fsi = state.player.faceUpSlots.firstIndex(where: {
            $0.contains { $0.id == tableCard.id }
        }) else { return }

        let handSlot = state.player.handSlots[hsi]

        // Move all hand slot cards to faceUp and into the table slot
        for card in handSlot {
            state.player.hand.removeAll { $0.id == card.id }
            state.player.faceUp.append(card)
        }
        state.player.faceUpSlots[fsi].append(contentsOf: handSlot)
        state.player.handSlots.remove(at: hsi)
        state.player.sortFaceUpSlots()

        // Refill hand from deck
        while state.player.hand.count < 3 && !state.deck.isEmpty {
            let card = state.deck.removeFirst()
            state.player.hand.append(card)
            state.player.handSlots.append([card])
        }
        state.player.sortHandSlots()
        HapticManager.tap()
    }

    /// Move all cards in the slot containing `tableCard` back to the hand, preserving their grouping.
    /// The freed table slot is refilled with the best available hand card.
    func unjoinTableSlot(tableCard: GameCard) {
        guard case .swap = state.phase else { return }
        guard let si = state.player.faceUpSlots.firstIndex(where: {
            $0.contains { $0.id == tableCard.id }
        }) else { return }
        guard state.player.faceUpSlots[si].count > 1 else { return }

        let slotCards = state.player.faceUpSlots[si]
        let movedIDs  = Set(slotCards.map(\.id))

        // Remove from flat faceUp array and slots
        for card in slotCards { state.player.faceUp.removeAll { $0.id == card.id } }
        state.player.faceUpSlots.remove(at: si)

        // Add to hand — keep as a group to preserve the arrangement
        state.player.hand.append(contentsOf: slotCards)
        if slotCards.count > 1 {
            state.player.handSlots.append(slotCards)
        } else {
            state.player.handSlots.append(contentsOf: slotCards.map { [$0] })
        }

        // Refill the freed table slot — pick lowest non-special card not just moved
        let candidates = state.player.hand.filter { !movedIDs.contains($0.id) }
        let moveCard = candidates.filter { !$0.isSpecial }.min(by: { $0.rank < $1.rank })
                    ?? candidates.first
        if let moveCard {
            state.player.removeCard(moveCard)
            state.player.faceUp.append(moveCard)
            state.player.faceUpSlots.append([moveCard])
        }

        state.player.sortFaceUpSlots()
        state.player.sortHandSlots()
        HapticManager.tap()
    }

    /// Merge two same-rank face-up table slots into one, then fill the freed slot
    /// from hand and draw from deck to restore hand to 3.
    func joinTableCards(_ card1: GameCard, _ card2: GameCard) {
        guard case .swap = state.phase else { return }
        guard card1.rank == card2.rank else { return }
        guard let si1 = state.player.faceUpSlots.firstIndex(where: { $0.contains { $0.id == card1.id } }),
              let si2 = state.player.faceUpSlots.firstIndex(where: { $0.contains { $0.id == card2.id } }),
              si1 != si2 else { return }

        // Merge — remove the higher index first to avoid shifting
        let lo = min(si1, si2), hi = max(si1, si2)
        let merged = state.player.faceUpSlots[lo] + state.player.faceUpSlots[hi]
        state.player.faceUpSlots.remove(at: hi)
        state.player.faceUpSlots[lo] = merged

        // Fill the freed slot from hand (prefer lowest non-special card)
        if let moveCard = state.player.hand
            .filter({ !$0.isSpecial })
            .min(by: { $0.rank < $1.rank })
            ?? state.player.hand.first
        {
            state.player.removeCard(moveCard)
            state.player.faceUp.append(moveCard)
            state.player.faceUpSlots.append([moveCard])
        }
        state.player.sortFaceUpSlots()

        // Refill hand from deck
        while state.player.hand.count < 3 && !state.deck.isEmpty {
            let card = state.deck.removeFirst()
            state.player.hand.append(card)
            state.player.handSlots.append([card])
        }
        state.player.sortHandSlots()
        HapticManager.tap()
    }

    /// Merge two same-rank hand slots into one.
    func joinHandCards(_ card1: GameCard, _ card2: GameCard) {
        guard case .swap = state.phase else { return }
        guard card1.rank == card2.rank else { return }
        guard let si1 = state.player.handSlots.firstIndex(where: { $0.contains { $0.id == card1.id } }),
              let si2 = state.player.handSlots.firstIndex(where: { $0.contains { $0.id == card2.id } }),
              si1 != si2 else { return }

        let lo = min(si1, si2), hi = max(si1, si2)
        let merged = state.player.handSlots[lo] + state.player.handSlots[hi]
        state.player.handSlots.remove(at: hi)
        state.player.handSlots[lo] = merged
        state.player.sortHandSlots()
        HapticManager.tap()
    }

    /// Split a grouped hand slot back into individual single-card slots.
    func unjoinHandSlot(handCard: GameCard) {
        guard case .swap = state.phase else { return }
        guard let si = state.player.handSlots.firstIndex(where: {
            $0.contains { $0.id == handCard.id }
        }) else { return }
        guard state.player.handSlots[si].count > 1 else { return }

        let slotCards = state.player.handSlots[si]
        state.player.handSlots.remove(at: si)
        state.player.handSlots.append(contentsOf: slotCards.map { [$0] })
        state.player.sortHandSlots()
        HapticManager.tap()
    }

    func confirmSwap() {
        guard case .swap = state.phase else { return }
        state.phase = .playing
        message     = L10n.Msg.yourTurn
        startTimer()
        checkAndDoAITurn()
    }

    // MARK: - Card selection (player hand)

    func toggleSelect(card: GameCard) {
        guard state.turn == .player, case .playing = state.phase else { return }
        guard state.player.phase != .faceDown else { return }   // faceDown handled separately

        // For face-up phase: tap selects / deselects the entire slot group at once
        if state.player.phase == .faceUp {
            let group = state.player.faceUpSlotGroup(for: card)
            let allSelected = group.allSatisfy { selectedCards.contains($0.id) }
            if allSelected {
                group.forEach { selectedCards.remove($0.id) }
            } else {
                selectedCards = Set(group.map(\.id))
            }
            HapticManager.tap()
            return
        }

        // Hand phase: individual card selection (same rank only)
        if selectedCards.contains(card.id) {
            selectedCards.remove(card.id)
        } else {
            if let first = selectedCardsList.first, first.rank != card.rank {
                selectedCards = [card.id]
            } else {
                selectedCards.insert(card.id)
            }
        }
        HapticManager.tap()
    }

    var selectedCardsList: [GameCard] {
        state.player.activeCards.filter { selectedCards.contains($0.id) }
    }

    var canPlaySelected: Bool {
        let cards = selectedCardsList
        guard !cards.isEmpty else { return false }
        return GameRules.canPlaySet(cards, pileTop: state.pileTop, isLowMode: state.isLowMode)
    }

    // MARK: - Play selected cards

    func playSelected() {
        guard state.turn == .player, case .playing = state.phase else { return }
        let cards = selectedCardsList
        guard !cards.isEmpty, canPlaySelected else { return }
        selectedCards = []
        executePlay(cards: cards, for: .player)
    }

    // MARK: - Dig (one-time hand ↔ pile swap)

    var canDig: Bool {
        guard state.turn == .player, case .playing = state.phase else { return false }
        guard state.player.phase == .hand else { return false }
        guard !state.pile.isEmpty, !state.player.hand.isEmpty else { return false }
        return !state.playerHasUsedDig
    }

    func digPile() {
        guard canDig else { return }
        let oldHand = state.player.hand
        let oldPile = state.pile
        // Hand → pile (sorted so lowest rank sits on top)
        state.pile        = oldHand.sorted { $0.rank > $1.rank }
        // Pile → hand
        state.player.hand   = oldPile
        state.player.handSlots = oldPile.map { [$0] }
        state.player.sortHandSlots()
        state.isLowMode         = false
        state.playerHasUsedDig  = true
        selectedCards           = []
        stats.currentStreak     = 0
        HapticManager.tap()
        message = L10n.Msg.youDug
        endTurn(for: .player)
    }

    // MARK: - Pick up pile (player)

    func pickUpPile() {
        guard state.turn == .player, case .playing = state.phase else { return }
        guard !state.pile.isEmpty else { return }
        let pileCards = state.pile
        state.player.hand.append(contentsOf: pileCards)
        state.player.handSlots.append(contentsOf: pileCards.map { [$0] })
        state.player.sortHandSlots()
        state.pile      = []
        state.isLowMode = false
        selectedCards   = []
        HapticManager.pickupAlert()
        stats.currentStreak = 0
        message             = L10n.Msg.youPickedUp
        flashPickup()
        endTurn(for: .player)
    }

    // MARK: - Face-down card play (player taps a blind card)

    func playFaceDown(card: GameCard) {
        guard state.turn == .player, case .playing = state.phase,
              state.player.phase == .faceDown else { return }

        state.player.faceDown.removeAll { $0 == card }
        stats.blindFlips += 1

        if GameRules.canPlay(card: card, pileTop: state.pileTop, isLowMode: state.isLowMode) {
            stats.blindSuccesses += 1
            // If this is the last card, show it before ending the game
            let isWinningPlay = state.player.hand.isEmpty
                             && state.player.faceUp.isEmpty
                             && state.player.faceDown.isEmpty
            if isWinningPlay {
                winningBlindCard = card
                message = L10n.Msg.blindWin
                HapticManager.win()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.winningBlindCard = nil
                    self.executePlay(cards: [card], for: .player)
                }
            } else {
                executePlay(cards: [card], for: .player)
            }
        } else {
            // Reveal the card face-up briefly before picking up
            blindReveal = card
            message     = L10n.Msg.cantPlay
            HapticManager.pickupAlert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                self.blindReveal = nil
                self.state.pile.append(card)
                let pickupCards = self.state.pile
                self.state.player.hand.append(contentsOf: pickupCards)
                self.state.player.handSlots.append(contentsOf: pickupCards.map { [$0] })
                self.state.player.sortHandSlots()
                self.state.pile          = []
                self.state.isLowMode     = false
                self.stats.currentStreak = 0
                self.endTurn(for: .player)
            }
        }
    }

    // MARK: - Core play execution

    private func executePlay(cards: [GameCard], for turn: Turn) {
        // Remove from player/AI state
        if turn == .player { state.player.removeCards(cards) }
        else               { state.ai.removeCards(cards) }

        let (burned, goAgain) = GameRules.applyPlay(cards: cards, state: &state)

        // Draw back up to 3
        if turn == .player {
            while state.player.hand.count < 3 && !state.deck.isEmpty {
                let card = state.deck.removeFirst()
                state.player.hand.append(card)
                state.player.handSlots.append([card])
            }
            state.player.sortHandSlots()
        } else {
            while state.ai.hand.count < 3 && !state.deck.isEmpty {
                state.ai.hand.append(state.deck.removeFirst())
            }
        }

        if turn == .player {
            stats.currentStreak += 1
            if stats.currentStreak > stats.longestStreak {
                stats.longestStreak = stats.currentStreak
            }
            if burned { stats.burns += 1 }
        }

        if burned {
            burnFlash = true
            HapticManager.playBurn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.burnFlash = false }
        } else if cards.first?.isReset == true {
            HapticManager.playReset()
        } else if cards.first?.isLow == true {
            HapticManager.playLow()
        } else {
            HapticManager.play()
        }

        // Check win
        if turn == .player && state.player.isEmpty {
            endGame(winner: .player); return
        }
        if turn == .ai && state.ai.isEmpty {
            endGame(winner: .ai); return
        }

        if goAgain {
            let rank = cards[0].displayRank
            let burnedByTen = cards.first!.isBurn
            if turn == .player {
                message = burnedByTen ? L10n.Msg.burnTen : L10n.Msg.burnQuad(rank)
            } else {
                message = burnedByTen ? L10n.Msg.aiBurnTen : L10n.Msg.aiBurnQuad(rank)
                // Hold the burn message on screen before the AI's next move
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.scheduleAITurn()
                }
            }
        } else {
            endTurn(for: turn)
        }
    }

    private func endTurn(for turn: Turn) {
        state.turn = (turn == .player) ? .ai : .player
        if state.turn == .player {
            updatePlayerMessage()
        } else {
            scheduleAITurn()
        }
    }

    private func endGame(winner: Turn) {
        stopTimer()
        state.phase = .gameOver(winner: winner)
        if winner == .player { HapticManager.win() } else { HapticManager.lose() }
        if winner == .player, ReviewPrompter.recordWin() { wantsReviewRequest = true }
    }

    /// Called by the view once it has shown the rating prompt.
    func reviewRequested() {
        wantsReviewRequest = false
    }

    // MARK: - AI turn

    private func scheduleAITurn() {
        guard case .playing = state.phase else { return }
        aiThinking = true
        message    = L10n.Msg.aiThinking

        let delay = Double.random(in: 0.8...1.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.aiThinking = false
            self?.doAITurn()
        }
    }

    private func doAITurn() {
        guard case .playing = state.phase, state.turn == .ai else { return }

        // Face-down phase: flip a random card
        if state.ai.phase == .faceDown {
            guard let card = state.ai.faceDown.randomElement() else { return }
            state.ai.faceDown.removeAll { $0 == card }
            if GameRules.canPlay(card: card, pileTop: state.pileTop, isLowMode: state.isLowMode) {
                executePlay(cards: [card], for: .ai)
            } else {
                state.pile.append(card)
                state.ai.hand.append(contentsOf: state.pile)
                state.pile      = []
                state.isLowMode = false
                message         = L10n.Msg.aiFlippedBad
                flashPickup()
                // Hold message on screen before handing back to the player
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
                    self?.endTurn(for: .ai)
                }
            }
            return
        }

        if let cards = AIPlayer.choosePlay(state: state) {
            let rankName = cards[0].displayRank
            message = cards.count > 1
                ? L10n.Msg.aiPlaysN(cards.count, rankName)
                : L10n.Msg.aiPlays(rankName + cards[0].suit.symbol)
            executePlay(cards: cards, for: .ai)
        } else {
            // Pick up pile — hold the message on screen before handing back to the player
            state.ai.hand.append(contentsOf: state.pile)
            state.pile      = []
            state.isLowMode = false
            message         = L10n.Msg.aiPickedUp
            flashPickup()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
                self?.endTurn(for: .ai)
            }
        }
    }

    private func checkAndDoAITurn() {
        if state.turn == .ai { scheduleAITurn() }
    }

    // MARK: - Helpers

    private func updatePlayerMessage() {
        guard !state.player.isEmpty else { return }
        let phase = state.player.phase
        if phase == .faceDown {
            message = L10n.Msg.tapBlind
            return
        }
        let canPlay = GameRules.hasPlayableCard(
            state.player.activeCards, pileTop: state.pileTop, isLowMode: state.isLowMode
        )
        if canPlay {
            message = L10n.Msg.selectPlay
        } else {
            message = L10n.Msg.noValidPlays
        }
    }

    var formattedTime: String {
        String(format: "%d:%02d", elapsedSecs / 60, elapsedSecs % 60)
    }

    var deckCount: Int { state.deck.count }

    var playerCanPlay: Bool {
        GameRules.hasPlayableCard(
            state.player.activeCards, pileTop: state.pileTop, isLowMode: state.isLowMode
        )
    }

    func isSelected(_ card: GameCard) -> Bool { selectedCards.contains(card.id) }

    func isPlayable(_ card: GameCard) -> Bool {
        guard state.turn == .player, case .playing = state.phase else { return false }
        // If we have a selection, only same rank can be added
        if let first = selectedCardsList.first, first.rank != card.rank { return false }
        return GameRules.canPlay(card: card, pileTop: state.pileTop, isLowMode: state.isLowMode)
    }

    private func flashPickup() {
        pickupFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { self.pickupFlash = false }
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.elapsedSecs += 1 }
    }
    private func stopTimer() { timer?.cancel(); timer = nil }
}
