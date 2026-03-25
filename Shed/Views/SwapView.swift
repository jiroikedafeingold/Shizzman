import SwiftUI

/// Pre-game card swap phase — player picks which 3 cards to leave face-up on the table.
struct SwapView: View {
    @ObservedObject var vm: GameViewModel

    /// Index into faceUpSlots of the currently selected table slot (nil = none).
    @State private var selectedSlotIdx: Int? = nil
    @State private var selectedHandCard: GameCard? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Text(L10n.Swap.arrangeTable)
                    .font(Theme.caption(10))
                    .tracking(3)
                    .foregroundStyle(Theme.tertiary)
                Text(L10n.Swap.instruction)
                    .font(Theme.caption(12))
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)

            // Face-up slots (table cards) — each slot may hold multiple same-rank cards
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Swap.tableCards)
                    .font(Theme.caption(10))
                    .tracking(2)
                    .foregroundStyle(Theme.tertiary)
                    .padding(.leading, 4)

                HStack(spacing: 10) {
                    ForEach(Array(vm.state.player.faceUpSlots.enumerated()), id: \.offset) { idx, slot in
                        VStack(spacing: 4) {
                            slotView(slot: slot, slotIdx: idx)
                                .onTapGesture { tapSlot(idx) }
                            // Hint shown when a grouped slot is selected
                            if selectedSlotIdx == idx && slot.count > 1 {
                                Text(L10n.Swap.tapToHand)
                                    .font(Theme.caption(9))
                                    .foregroundStyle(Theme.secondary)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: selectedSlotIdx == idx)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.rMd)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                            .strokeBorder(Theme.border, lineWidth: 0.5))
                )
                .pShadow()
            }
            .padding(.horizontal, 24)

            // Hint icons
            HStack(spacing: 20) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundStyle(Theme.tertiary)
                if canJoinAnything {
                    Image(systemName: "link")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundStyle(Theme.hint.opacity(0.8))
                }
            }
            .padding(.vertical, 14)

            // Hand
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Swap.yourHand)
                    .font(Theme.caption(10))
                    .tracking(2)
                    .foregroundStyle(Theme.tertiary)
                    .padding(.leading, 4)

                HStack(spacing: 10) {
                    ForEach(vm.state.player.hand.sorted { $0.rank < $1.rank }) { card in
                        CardView(card: card, isSelected: selectedHandCard == card)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.rSm)
                                    .strokeBorder(
                                        selectedHandCard == card ? Theme.hint : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .overlay(alignment: .topTrailing) {
                                if joinBadgeVisible(for: card) {
                                    Image(systemName: "link")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(3)
                                        .background(Circle().fill(Theme.hint))
                                        .offset(x: 4, y: -4)
                                }
                            }
                            .onTapGesture { tapHand(card) }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.rMd)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                            .strokeBorder(Theme.border, lineWidth: 0.5))
                )
                .pShadow()
            }
            .padding(.horizontal, 24)

            Spacer()

            // Special card legend
            specialLegend
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Ready button
            Button { vm.confirmSwap() } label: {
                Text(L10n.Swap.ready)
                    .font(Theme.headline())
                    .foregroundStyle(Theme.felt)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: Theme.rMd).fill(Theme.valid))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Slot view

    /// Renders a face-up slot: stacked card silhouettes behind the top card, plus a count badge.
    @ViewBuilder
    private func slotView(slot: [GameCard], slotIdx: Int) -> some View {
        let isSelected = selectedSlotIdx == slotIdx
        ZStack(alignment: .topTrailing) {
            // Stacked shadow cards behind (offset for depth)
            ZStack {
                ForEach(1..<min(slot.count, 3), id: \.self) { depth in
                    RoundedRectangle(cornerRadius: Theme.rSm)
                        .fill(Theme.surface)
                        .frame(width: Theme.cW, height: Theme.cH)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.rSm)
                                .strokeBorder(Theme.border, lineWidth: 0.5)
                        )
                        .offset(x: CGFloat(depth) * 3, y: CGFloat(depth) * -3)
                        .cShadow()
                }
                // Top card
                CardView(card: slot.first!, isSelected: isSelected)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .strokeBorder(
                                isSelected ? Theme.hint : Color.clear,
                                lineWidth: 2
                            )
                    )
            }

            // Count badge when grouped
            if slot.count > 1 {
                Text("×\(slot.count)")
                    .font(Theme.caption(9))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.hint))
                    .offset(x: 6, y: -6)
            }
        }
        .frame(width: Theme.cW + CGFloat(min(slot.count - 1, 2)) * 3,
               height: Theme.cH + CGFloat(min(slot.count - 1, 2)) * 3)
    }

    // MARK: - Tap logic

    private func tapSlot(_ idx: Int) {
        guard idx < vm.state.player.faceUpSlots.count else { return }
        HapticManager.tap()

        let slot = vm.state.player.faceUpSlots[idx]
        let rep  = slot.first!          // representative card for rank comparison

        if let hc = selectedHandCard {
            // Hand card already selected
            if hc.rank == rep.rank {
                vm.joinHandCardToFaceUpSlot(handCard: hc, tableCard: rep)
            } else if slot.count == 1 {
                vm.swapPlayerCards(handCard: hc, faceUpCard: rep)
            }
            // multi-card slot + different rank → no action
            selectedHandCard = nil
            selectedSlotIdx  = nil

        } else if let prevIdx = selectedSlotIdx {
            let prevSlot = vm.state.player.faceUpSlots[prevIdx]
            let prevRep  = prevSlot.first!
            if prevIdx == idx {
                // Second tap: grouped slot → move to hand; single-card slot → deselect
                if prevSlot.count > 1 {
                    vm.unjoinTableSlot(tableCard: prevRep)
                }
                selectedSlotIdx = nil
            } else if prevRep.rank == rep.rank {
                // Same rank → join the two table slots
                vm.joinTableCards(prevRep, rep)
                selectedSlotIdx = nil
            } else {
                // Different rank → switch selection to this slot
                selectedSlotIdx = idx
            }
        } else {
            selectedSlotIdx = idx
        }
    }

    private func tapHand(_ card: GameCard) {
        HapticManager.tap()

        if let idx = selectedSlotIdx, idx < vm.state.player.faceUpSlots.count {
            let slot = vm.state.player.faceUpSlots[idx]
            let rep  = slot.first!
            if card.rank == rep.rank {
                vm.joinHandCardToFaceUpSlot(handCard: card, tableCard: rep)
            } else if slot.count == 1 {
                vm.swapPlayerCards(handCard: card, faceUpCard: rep)
            }
            selectedHandCard = nil
            selectedSlotIdx  = nil
        } else {
            selectedHandCard = (selectedHandCard == card) ? nil : card
        }
    }

    // MARK: - Helpers

    /// True when any hand card shares a rank with any table slot (join is possible).
    private var canJoinAnything: Bool {
        let tableRanks = Set(vm.state.player.faceUpSlots.compactMap { $0.first?.rank })
        return vm.state.player.hand.contains { tableRanks.contains($0.rank) }
    }

    /// Show a link badge on a hand card when a join is possible for it.
    private func joinBadgeVisible(for card: GameCard) -> Bool {
        let tableRanks = Set(vm.state.player.faceUpSlots.compactMap { $0.first?.rank })
        return tableRanks.contains(card.rank)
    }

    // MARK: - Legend

    private var specialLegend: some View {
        HStack(spacing: 16) {
            legendItem("2", color: Theme.reset, text: L10n.Swap.alwaysPlayable)
            legendItem("7", color: Theme.low,   text: L10n.Swap.forcesLow)
            legendItem("10", color: Theme.burn, text: L10n.Swap.burnsPile)
        }
        .font(Theme.caption(10))
    }

    private func legendItem(_ label: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(Theme.caption(10)).foregroundStyle(color)
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background(Capsule().fill(color.opacity(0.18)))
            Text(text).font(Theme.caption(10)).foregroundStyle(Theme.tertiary)
        }
    }
}
