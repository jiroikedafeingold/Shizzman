import StoreKit
import SwiftUI

struct GameView: View {
    @EnvironmentObject private var settings: SettingsStore
    @ObservedObject var vm: GameViewModel
    let onHome: () -> Void
    @Environment(\.requestReview) private var requestReview

    @State private var showYourTurnFlash = false
    @State private var showPilePeek      = false
    @State private var showRules         = false

    var body: some View {
        ZStack {
            settings.felt.ignoresSafeArea()

            switch vm.state.phase {
            case .swap:
                VStack(spacing: 0) {
                    navBar(title: L10n.Game.arrangeHand)
                    SwapView(vm: vm)
                }
                .iPadContentWidth()
                .transition(.opacity)

            case .playing:
                VStack(spacing: 0) {
                    playingNavBar
                    playingContent
                }
                .iPadContentWidth()
                .transition(.opacity)
                .onChange(of: vm.state.turn) { _, newTurn in
                    if newTurn == .player, case .playing = vm.state.phase {
                        showYourTurnFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            showYourTurnFlash = false
                        }
                    }
                }

            case .gameOver(let winner):
                GameOverView(
                    winner:    winner,
                    time:      vm.formattedTime,
                    stats:     vm.stats,
                    onRematch: { vm.startNewGame() },
                    onHome:    onHome
                )
                .transition(.opacity)
                // After a win, let the confetti play, then ask for a rating if it's due.
                .task {
                    guard vm.wantsReviewRequest else { return }
                    vm.reviewRequested()
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }   // left the screen already
                    requestReview()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: {
            if case .playing = vm.state.phase { return 1 }
            if case .swap    = vm.state.phase { return 0 }
            return 2
        }())
        .overlay(yourTurnOverlay)
        .overlay(pickupFlashOverlay)
        .overlay(blindRevealOverlay)
        .overlay(winningBlindOverlay)
    }

    // MARK: - Nav bar (swap phase)

    private func navBar(title: String) -> some View {
        HStack {
            Button(action: onHome) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Theme.surface)
                        .overlay(Circle().strokeBorder(Theme.border, lineWidth: 0.5)))
            }
            Spacer()
            Text(title)
                .font(Theme.caption(15))
                .tracking(4)
                .foregroundStyle(Theme.tertiary)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Nav bar (playing phase — includes turn indicator)

    private var playingNavBar: some View {
        let isPlayerTurn = vm.state.turn == .player
        return HStack(spacing: 10) {
            Button(action: onHome) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.surface)
                        .overlay(Circle().strokeBorder(Theme.border, lineWidth: 0.5)))
            }
            Circle()
                .fill(isPlayerTurn ? Theme.valid : Theme.secondary.opacity(0.45))
                .frame(width: 7, height: 7)
                .animation(.easeInOut(duration: 0.3), value: isPlayerTurn)
            Text(isPlayerTurn ? L10n.Game.yourTurn : (vm.aiThinking ? L10n.Game.aiThinking : L10n.Game.aiTurn))
                .font(Theme.caption(15))
                .tracking(2)
                .foregroundStyle(isPlayerTurn ? Theme.valid : Theme.secondary)
                .animation(.easeInOut(duration: 0.3), value: isPlayerTurn)
            Spacer()
            Text(vm.formattedTime)
                .font(Theme.mono(15))
                .foregroundStyle(Theme.tertiary)
            Button { showRules = true } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Theme.tertiary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .sheet(isPresented: $showRules) {
            RulesSheet()
                .environmentObject(settings)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(settings.felt)
        }
    }

    // MARK: - Your-turn flash overlay

    @ViewBuilder
    private var yourTurnOverlay: some View {
        if showYourTurnFlash {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                Text(L10n.Game.yourTurn)
                    .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                    .tracking(10)
                    .foregroundStyle(Theme.valid)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.rMd)
                            .fill(Theme.surface.opacity(0.92))
                            .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                .strokeBorder(Theme.valid.opacity(0.4), lineWidth: 1))
                    )
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: showYourTurnFlash)
        }
    }

    // MARK: - Pick-up pile flash overlay

    @ViewBuilder
    private var pickupFlashOverlay: some View {
        if vm.pickupFlash {
            ZStack {
                Color.black.opacity(0.35).ignoresSafeArea()
                Text(vm.message)
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.warn)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.rMd)
                            .fill(Theme.surface.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                .strokeBorder(Theme.warn.opacity(0.45), lineWidth: 1))
                    )
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: vm.pickupFlash)
        }
    }

    // MARK: - Blind card reveal overlay

    @ViewBuilder
    private var blindRevealOverlay: some View {
        if let card = vm.blindReveal {
            ZStack {
                Color.black.opacity(0.5).ignoresSafeArea()
                VStack(spacing: 16) {
                    CardView(card: card)
                        .frame(width: Theme.cardW * 1.8, height: Theme.cardH * 1.8)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))

                    Text(L10n.Msg.cantPlay)
                        .font(Theme.label(16))
                        .foregroundStyle(Theme.warn)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.rMd)
                                .fill(Theme.surface.opacity(0.95))
                                .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                    .strokeBorder(Theme.warn.opacity(0.4), lineWidth: 1))
                        )
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: vm.blindReveal != nil)
        }
    }

    // MARK: - Winning blind card reveal overlay

    @ViewBuilder
    private var winningBlindOverlay: some View {
        if let card = vm.winningBlindCard {
            ZStack {
                Color.black.opacity(0.65).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 48))
                    CardView(card: card)
                        .frame(width: Theme.cardW * 1.8, height: Theme.cardH * 1.8)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                    Text(L10n.Msg.blindWin)
                        .font(Theme.label(16))
                        .foregroundStyle(Theme.valid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.rMd)
                                .fill(Theme.surface.opacity(0.95))
                                .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                    .strokeBorder(Theme.valid.opacity(0.5), lineWidth: 1))
                        )
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: vm.winningBlindCard != nil)
        }
    }

    // MARK: - Playing content

    private var playingContent: some View {
        VStack(spacing: 0) {
            // AI area
            aiArea
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            Divider().background(Theme.border).padding(.horizontal, 16)

            Spacer(minLength: 12)

            // Center: pile + deck
            centerArea

            Spacer(minLength: 12)

            Divider().background(Theme.border).padding(.horizontal, 16)

            // Message
            messageBar
                .padding(.vertical, 6)

            // Player area
            playerArea
                .padding(.horizontal, 16)

            Spacer(minLength: 12)

            // Action buttons
            actionButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 4)
        }
    }

    // MARK: - AI area

    private var aiArea: some View {
        VStack(spacing: 14) {
            HStack {
                Text(L10n.Game.opponent)
                    .font(Theme.caption(15)).tracking(3).foregroundStyle(Theme.tertiary)
                if vm.state.ai.phase == .faceDown {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("BLIND")
                            .font(Theme.caption(13)).tracking(1)
                    }
                    .foregroundStyle(Theme.warn)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.warn.opacity(0.15))
                        .overlay(Capsule().strokeBorder(Theme.warn.opacity(0.4), lineWidth: 0.5)))
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: vm.state.ai.phase == .faceDown)
                }
                Spacer()
                if vm.aiThinking {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.65).tint(Theme.secondary)
                        Text(L10n.Game.thinking).font(Theme.caption(15)).foregroundStyle(Theme.secondary)
                    }
                } else {
                    Text(L10n.Game.cardsCount(vm.state.ai.totalCards))
                        .font(Theme.caption(15)).foregroundStyle(Theme.tertiary)
                }
            }

            HStack(spacing: 24) {
                // Face-down
                cardRow(
                    cards: vm.state.ai.faceDown,
                    label: L10n.Game.blind,
                    showFaceDown: true,
                    isActive: vm.state.ai.phase == .faceDown
                )

                Spacer()

                // Face-up (hidden from player)
                cardRow(
                    cards: vm.state.ai.faceUp,
                    label: L10n.Game.table,
                    showFaceDown: true,
                    isActive: vm.state.ai.phase == .faceUp
                )

                Spacer()

                // Hand count
                VStack(spacing: 4) {
                    ZStack {
                        ForEach(0..<min(vm.state.ai.hand.count, 3), id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.cardBack)
                                .frame(width: 22 * Theme.padScale, height: 32 * Theme.padScale)
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5))
                                .offset(x: CGFloat(i) * 4, y: CGFloat(i) * -2)
                                .cShadow()
                        }
                    }
                    .frame(width: 30 * Theme.padScale, height: 36 * Theme.padScale)
                    Text(L10n.Game.handCount(vm.state.ai.hand.count))
                        .font(Theme.caption(14)).foregroundStyle(Theme.tertiary)
                        .fixedSize()
                }
            }
        }
    }

    // MARK: - Center area

    private var centerArea: some View {
        HStack(spacing: 0) {
            // Dig button — left of pile, one-time swap
            ZStack {
                if vm.canDig && settings.digEnabled {
                    Button { vm.digPile() } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: .light))
                            Text(L10n.Game.digPile)
                                .font(Theme.caption(12))
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.reset)
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.rMd)
                                .fill(Theme.reset.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                    .strokeBorder(Theme.reset.opacity(0.35), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .frame(width: 80)
            .animation(.easeInOut(duration: 0.2), value: vm.canDig)

            Spacer()

            PileView(
                state:     vm.state,
                burnFlash: vm.burnFlash,
                deckCount: vm.deckCount
            )
            .onTapGesture {
                guard settings.pilePeekEnabled, !vm.state.pile.isEmpty else { return }
                HapticManager.tap()
                showPilePeek = true
            }
            .sheet(isPresented: $showPilePeek) {
                PilePeekSheet(pile: vm.state.pile)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.felt)
            }

            Spacer()
            // Balance the left side so PileView stays centred
            Color.clear.frame(width: 80)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Message bar

    private var messageBar: some View {
        Text(vm.message)
            .font(Theme.label(16))
            .foregroundStyle(Theme.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.2), value: vm.message)
    }

    // MARK: - Player area

    private var playerArea: some View {
        VStack(spacing: 14) {
            HStack {
                Text(L10n.Game.you)
                    .font(Theme.caption(15)).tracking(3).foregroundStyle(Theme.tertiary)
                Spacer()
                Text(L10n.Game.phaseLabel(vm.state.player.phase).uppercased())
                    .font(Theme.caption(15)).tracking(2)
                    .foregroundStyle(Theme.tertiary)
            }

            // Face-down cards (only shown in faceDown phase)
            if vm.state.player.phase == .faceDown {
                HStack(spacing: 8) {
                    ForEach(vm.state.player.faceDown) { card in
                        CardView(card: card, faceDown: true)
                            .onTapGesture { vm.playFaceDown(card: card) }
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.rSm)
                                    .strokeBorder(Theme.warn.opacity(0.6), lineWidth: 1.5)
                            )
                    }
                    Text(L10n.Game.tapBlind)
                        .font(Theme.caption(15)).foregroundStyle(Theme.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Face-up table cards — shown as slot groups (always visible unless fully empty)
            if !vm.state.player.faceUp.isEmpty || vm.state.player.phase == .faceUp {
                HStack(spacing: 8) {
                    ForEach(vm.state.player.faceUpSlots.filter { !$0.isEmpty }, id: \.first!.id) { slot in
                        let active       = vm.state.player.phase == .faceUp
                        let topCard      = slot.first!
                        let groupSelected = slot.allSatisfy { vm.isSelected($0) }
                        ZStack(alignment: .topTrailing) {
                            // Stacked depth silhouettes
                            ZStack {
                                ForEach(1..<min(slot.count, 3), id: \.self) { depth in
                                    RoundedRectangle(cornerRadius: Theme.rSm)
                                        .fill(Theme.surface)
                                        .frame(width: Theme.cardW * 0.85, height: Theme.cardH * 0.85)
                                        .overlay(RoundedRectangle(cornerRadius: Theme.rSm)
                                            .strokeBorder(Theme.border, lineWidth: 0.5))
                                        .offset(x: CGFloat(depth) * 2, y: CGFloat(depth) * -2)
                                }
                                CardView(
                                    card:       topCard,
                                    isSelected: groupSelected,
                                    isPlayable: active ? vm.isPlayable(topCard) : true
                                )
                                .frame(width: Theme.cardW * 0.85, height: Theme.cardH * 0.85)
                            }
                            .onTapGesture { if active { vm.toggleSelect(card: topCard) } }
                            .opacity(active ? 1 : 0.55)
                            // Count badge
                            if slot.count > 1 {
                                Text("×\(slot.count)")
                                    .font(Theme.caption(8))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Theme.hint))
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    Text(L10n.Game.table)
                        .font(Theme.caption(14)).foregroundStyle(Theme.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Hand (main playing area — scrollable for large hands)
            if !vm.state.player.hand.isEmpty {
                let sortedHand = vm.state.player.hand.sorted { $0.rank < $1.rank }
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sortedHand) { card in
                                let active = vm.state.player.phase == .hand && vm.state.turn == .player
                                CardView(
                                    card:       card,
                                    isSelected: vm.isSelected(card),
                                    isPlayable: active ? vm.isPlayable(card) : true
                                )
                                .offset(y: vm.isSelected(card) ? -10 : 0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: vm.isSelected(card))
                                .onTapGesture { if active { vm.toggleSelect(card: card) } }
                                .id(card.id)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 14)
                    }
                    .frame(height: Theme.cardH + 28)
                    .onChange(of: vm.state.turn) { _, newTurn in
                        guard newTurn == .player else { return }
                        if let target = sortedHand.first(where: { vm.isPlayable($0) }) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(target.id, anchor: .leading)
                            }
                        }
                    }
                    .onAppear {
                        if let target = sortedHand.first(where: { vm.isPlayable($0) }) {
                            proxy.scrollTo(target.id, anchor: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var actionButtons: some View {
        if case .playing = vm.state.phase, vm.state.turn == .player {
            HStack(spacing: 12) {
                // Play selected
                Button { vm.playSelected() } label: {
                    Text(vm.selectedCardsList.isEmpty ? L10n.Game.selectCard : (vm.selectedCardsList.count == 1 ? L10n.Game.playCard : L10n.Game.playCards(vm.selectedCardsList.count)))
                        .font(Theme.headline(15))
                        .foregroundStyle(vm.canPlaySelected ? Theme.felt : Theme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.rMd)
                                .fill(vm.canPlaySelected ? Theme.valid : Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                    .strokeBorder(vm.canPlaySelected ? Color.clear : Theme.border, lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!vm.canPlaySelected)

                // Pick up pile
                Button { vm.pickUpPile() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                        Text(L10n.Game.pickPile)
                    }
                    .font(Theme.label(14))
                    .foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.rMd)
                            .fill(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                                .strokeBorder(Theme.border, lineWidth: 0.5))
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.state.pile.isEmpty)
                .opacity(vm.state.pile.isEmpty ? 0.4 : 1)
            }
        }
    }

    // MARK: - Reusable card row

    private func cardRow(cards: [GameCard], label: String, showFaceDown: Bool, isActive: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(cards) { card in
                    CardView(
                        card:     card,
                        faceDown: showFaceDown,
                        isPlayable: isActive
                    )
                    .frame(width: Theme.cardW * 0.7, height: Theme.cardH * 0.7)
                }
            }
            Text(label)
                .font(Theme.caption(14)).foregroundStyle(Theme.tertiary)
        }
    }
}
