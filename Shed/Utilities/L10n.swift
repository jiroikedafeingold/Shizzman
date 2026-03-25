import Foundation

// Centralised access to all localised strings.
// Usage: L10n.Home.playButton, L10n.Msg.burnGoAgain, etc.

enum L10n {

    // MARK: - Home screen

    enum Home {
        static let subtitle    = loc("home.subtitle")
        static let info1       = loc("home.info1")
        static let info2       = loc("home.info2")
        static let info3       = loc("home.info3")
        static let info4       = loc("home.info4")
        static let playButton  = loc("home.play_button")
        static let resets      = loc("home.resets")
        static let forcesLow   = loc("home.forces_low")
        static let burnsPile   = loc("home.burns_pile")
    }

    // MARK: - Game screen

    enum Game {
        static let arrangeHand = loc("game.arrange_hand")
        static let opponent    = loc("game.opponent")
        static let thinking    = loc("game.thinking")
        static let blind       = loc("game.blind")
        static let table       = loc("game.table")
        static let yourTurn    = loc("game.your_turn")
        static let aiThinking  = loc("game.ai_thinking")
        static let aiTurn      = loc("game.ai_turn")
        static let pickPile    = loc("game.pick_pile")
        static let digPile     = loc("game.dig_pile")
        static let selectCard  = loc("game.select_card")
        static let playCard    = loc("game.play_card")
        static let you         = loc("game.you")
        static let tapBlind    = loc("game.tap_blind")

        static func cardsCount(_ n: Int) -> String { fmt("game.cards_count", n) }
        static func handCount(_ n: Int)  -> String { fmt("game.hand_count", n) }
        static func playCards(_ n: Int)  -> String { fmt("game.play_cards", n) }
        static func phaseLabel(_ phase: PlayerPhase) -> String {
            switch phase {
            case .hand:     return loc("game.phase_hand")
            case .faceUp:   return loc("game.phase_face_up")
            case .faceDown: return loc("game.phase_face_down")
            }
        }
    }

    // MARK: - In-game messages (set on GameViewModel.message)

    enum Msg {
        static let arrange      = loc("msg.arrange")
        static let yourTurn     = loc("msg.your_turn")
        static let aiThinking   = loc("msg.ai_thinking")
        static let youPickedUp  = loc("msg.you_picked_up")
        static let cantPlay     = loc("msg.cant_play")
        static let aiFlippedBad = loc("msg.ai_flipped_bad")
        static let aiPickedUp   = loc("msg.ai_picked_up")
        static let burnTen      = loc("msg.burn_ten")
        static let aiBurnTen    = loc("msg.ai_burn_ten")
        static func burnQuad(_ rank: String)   -> String { fmt("msg.burn_quad",    rank) }
        static func aiBurnQuad(_ rank: String) -> String { fmt("msg.ai_burn_quad", rank) }
        static let tapBlind     = loc("msg.tap_blind")
        static let selectPlay   = loc("msg.select_play")
        static let noValidPlays = loc("msg.no_valid_plays")
        static let youDug       = loc("msg.you_dug")
        static let blindWin     = loc("msg.blind_win")

        static func aiPlays(_ card: String)             -> String { fmt("msg.ai_plays", card) }
        static func aiPlaysN(_ n: Int, _ rank: String)  -> String { fmt2("msg.ai_plays_n", n, rank) }
    }

    // MARK: - Swap / arrange phase

    enum Swap {
        static let arrangeTable  = loc("swap.arrange_table")
        static let instruction   = loc("swap.instruction")
        static let tableCards    = loc("swap.table_cards")
        static let yourHand      = loc("swap.your_hand")
        static let ready         = loc("swap.ready")
        static let tapToHand      = loc("swap.tap_to_hand")
        static let tapToSeparate  = loc("swap.tap_to_separate")
        static let alwaysPlayable = loc("swap.always_playable")
        static let forcesLow     = loc("swap.forces_low")
        static let burnsPile     = loc("swap.burns_pile")
    }

    // MARK: - Game-over screen

    enum GameOver {
        static let youWin      = loc("gameover.you_win")
        static let youLose     = loc("gameover.you_lose")
        static let clearedHand = loc("gameover.cleared_hand")
        static let aiShed      = loc("gameover.ai_shed")
        static let time        = loc("gameover.time")
        static let burns       = loc("gameover.burns")
        static let bestStreak  = loc("gameover.best_streak")
        static let blindLuck   = loc("gameover.blind_luck")
        static let playAgain   = loc("gameover.play_again")
        static let home        = loc("gameover.home")
    }

    // MARK: - Pile-peek sheet

    enum PilePeek {
        static let title = loc("pile_peek.title")
        static let top   = loc("pile_peek.top")
        static func subtitle(_ n: Int) -> String { fmt("pile_peek.subtitle", n) }
    }

    // MARK: - Rules sheet

    enum Rules {
        static let title  = loc("rules.title")
        static let done   = loc("rules.done")

        enum Objective { static let title = loc("rules.objective.title"); static let text  = loc("rules.objective.text") }
        enum Setup     { static let title = loc("rules.setup.title");     static let text1 = loc("rules.setup.text1"); static let text2 = loc("rules.setup.text2") }
        enum Join      { static let title = loc("rules.join.title");      static let text1 = loc("rules.join.text1");  static let text2 = loc("rules.join.text2") }
        enum Turn      { static let title = loc("rules.turn.title");      static let text1 = loc("rules.turn.text1"); static let text2 = loc("rules.turn.text2"); static let text3 = loc("rules.turn.text3") }
        enum Zones     { static let title = loc("rules.zones.title");     static let text1 = loc("rules.zones.text1"); static let text2 = loc("rules.zones.text2") }
        enum Special   { static let title = loc("rules.special.title");   static let text2 = loc("rules.special.text2"); static let text7 = loc("rules.special.text7"); static let text10 = loc("rules.special.text10") }
        enum Burn      { static let title = loc("rules.burn.title");      static let text  = loc("rules.burn.text") }
        enum Peek      { static let title = loc("rules.peek.title");      static let text1 = loc("rules.peek.text1"); static let text2 = loc("rules.peek.text2") }
        enum Dig       { static let title = loc("rules.dig.title"); static let text1 = loc("rules.dig.text1"); static let text2 = loc("rules.dig.text2") }
        enum Win       { static let title = loc("rules.win.title"); static let text  = loc("rules.win.text") }
    }

    // MARK: - Settings screen

    enum Settings {
        static let title                = loc("settings.title")
        static let done                 = loc("settings.done")
        static let sectionGameplay      = loc("settings.section.gameplay")
        static let sectionTableColor    = loc("settings.section.table_color")
        static let digTitle             = loc("settings.dig.title")
        static let digSubtitle          = loc("settings.dig.subtitle")
        static let peekTitle            = loc("settings.peek.title")
        static let peekSubtitle         = loc("settings.peek.subtitle")
        static let hapticsTitle         = loc("settings.haptics.title")
        static let hapticsSubtitle      = loc("settings.haptics.subtitle")
    }

    // MARK: - Helpers

    private static func loc(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
    private static func fmt(_ key: String, _ a1: CVarArg) -> String {
        String(format: NSLocalizedString(key, comment: ""), a1)
    }
    private static func fmt2(_ key: String, _ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: NSLocalizedString(key, comment: ""), a1, a2)
    }
}
