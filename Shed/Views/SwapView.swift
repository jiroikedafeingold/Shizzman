import SwiftUI

/// Pre-game card swap phase — player picks which 3 cards to leave face-up on the table.
struct SwapView: View {
    @ObservedObject var vm: GameViewModel

    /// Index into faceUpSlots of the currently selected table slot (nil = none).
    @State private var selectedSlotIdx:     Int? = nil
    @State private var selectedHandSlotIdx: Int? = nil

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
                            slotView(slot: slot, isSelected: selectedSlotIdx == idx)
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

            // Hand — shown as grouped slots, same style as table cards
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Swap.yourHand)
                    .font(Theme.caption(10))
                    .tracking(2)
                    .foregroundStyle(Theme.tertiary)
                    .padding(.leading, 4)

                HStack(spacing: 10) {
                    ForEach(Array(vm.state.player.handSlots.enumerated()), id: \.offset) { idx, slot in
                        VStack(spacing: 4) {
                            slotView(slot: slot, isSelected: selectedHandSlotIdx == idx)
                                .overlay(alignment: .topLeading) {
                                    if handSlotJoinBadgeVisible(for: slot) {
                                        Image(systemName: "link")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(3)
                                            .background(Circle().fill(Theme.hint))
                                            .offset(x: -4, y: -4)
                                    }
                                }
                                .onTapGesture { tapHandSlot(idx) }
                            // Hint shown when a grouped hand slot is selected
                            if selectedHandSlotIdx == idx && slot.count > 1 {
                                Text(L10n.Swap.tapToSeparate)
                                    .font(Theme.caption(9))
                                    .foregroundStyle(Theme.secondary)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: selectedHandSlotIdx == idx)
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
        .iPadContentWidth()
    }

    // MARK: - Slot view (shared by table cards and hand slots)

    /// Renders a card slot: stacked card silhouettes behind the top card, plus a count badge.
    @ViewBuilder
    private func slotView(slot: [GameCard], isSelected: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            // Stacked shadow cards behind (offset for depth)
            ZStack {
                ForEach(1..<min(slot.count, 3), id: \.self) { depth in
                    RoundedRectangle(cornerRadius: Theme.rSm)
                        .fill(Theme.surface)
                        .frame(width: Theme.cardW, height: Theme.cardH)
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
        .frame(width: Theme.cardW + CGFloat(min(slot.count - 1, 2)) * 3,
               height: Theme.cardH + CGFloat(min(slot.count - 1, 2)) * 3)
    }

    // MARK: - Tap logic

    private func tapSlot(_ idx: Int) {
        guard idx < vm.state.player.faceUpSlots.count else { return }
        HapticManager.tap()

        let slot = vm.state.player.faceUpSlots[idx]
        let rep  = slot.first!

        if let handSlotIdx = selectedHandSlotIdx {
            // Hand slot was selected — interact with this table slot
            guard handSlotIdx < vm.state.player.handSlots.count else {
                selectedHandSlotIdx = nil; return
            }
            let handSlot = vm.state.player.handSlots[handSlotIdx]
            let handRep  = handSlot.first!
            if handRep.rank == rep.rank {
                vm.joinHandSlotToFaceUpSlot(handCard: handRep, tableCard: rep)
            } else if slot.count == 1 && handSlot.count == 1 {
                vm.swapPlayerCards(handCard: handRep, faceUpCard: rep)
            }
            selectedHandSlotIdx = nil
            selectedSlotIdx     = nil

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
                selectedHandSlotIdx = nil
            }
        } else {
            selectedSlotIdx = idx
            selectedHandSlotIdx = nil
        }
    }

    private func tapHandSlot(_ idx: Int) {
        guard idx < vm.state.player.handSlots.count else { return }
        HapticManager.tap()

        let handSlot = vm.state.player.handSlots[idx]
        let handRep  = handSlot.first!

        if let tableIdx = selectedSlotIdx, tableIdx < vm.state.player.faceUpSlots.count {
            // Table slot was selected — interact with this hand slot
            let tableSlot = vm.state.player.faceUpSlots[tableIdx]
            let tableRep  = tableSlot.first!
            if handRep.rank == tableRep.rank {
                vm.joinHandSlotToFaceUpSlot(handCard: handRep, tableCard: tableRep)
            } else if tableSlot.count == 1 && handSlot.count == 1 {
                vm.swapPlayerCards(handCard: handRep, faceUpCard: tableRep)
            }
            selectedHandSlotIdx = nil
            selectedSlotIdx     = nil

        } else if let prevIdx = selectedHandSlotIdx {
            guard prevIdx < vm.state.player.handSlots.count else {
                selectedHandSlotIdx = idx; return
            }
            let prevSlot = vm.state.player.handSlots[prevIdx]
            let prevRep  = prevSlot.first!
            if prevIdx == idx {
                // Second tap: grouped hand slot → unjoin; single → deselect
                if prevSlot.count > 1 {
                    vm.unjoinHandSlot(handCard: prevRep)
                }
                selectedHandSlotIdx = nil
            } else if prevRep.rank == handRep.rank {
                // Same rank → join the two hand slots
                vm.joinHandCards(prevRep, handRep)
                selectedHandSlotIdx = nil
            } else {
                // Different rank → switch selection
                selectedHandSlotIdx = idx
                selectedSlotIdx = nil
            }
        } else {
            selectedHandSlotIdx = idx
            selectedSlotIdx = nil
        }
    }

    // MARK: - Helpers

    /// True when any join is possible (hand-to-table or hand-to-hand).
    private var canJoinAnything: Bool {
        let tableRanks = Set(vm.state.player.faceUpSlots.compactMap { $0.first?.rank })
        let handRanks  = vm.state.player.handSlots.compactMap { $0.first?.rank }
        let canJoinToTable = handRanks.contains { tableRanks.contains($0) }
        let canJoinInHand  = Set(handRanks).count < handRanks.count
        return canJoinToTable || canJoinInHand
    }

    /// Show a link badge on a hand slot when a join is possible for it.
    private func handSlotJoinBadgeVisible(for slot: [GameCard]) -> Bool {
        guard let rank = slot.first?.rank else { return false }
        let tableRanks = Set(vm.state.player.faceUpSlots.compactMap { $0.first?.rank })
        if tableRanks.contains(rank) { return true }
        // Check if another hand slot has the same rank
        let otherHandRanks = vm.state.player.handSlots
            .filter { $0.first?.id != slot.first?.id }
            .compactMap { $0.first?.rank }
        return otherHandRanks.contains(rank)
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
