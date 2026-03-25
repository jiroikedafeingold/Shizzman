import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var showGame     = false
    @State private var showRules    = false
    @State private var showSettings = false
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            settings.felt.ignoresSafeArea()

            if showGame {
                GameView(vm: vm, onHome: { withAnimation(.easeInOut(duration: 0.35)) { showGame = false } })
                    .environmentObject(settings)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                homeContent
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showGame)
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                cardFan
                    .padding(.bottom, 4)

                Text("SHIZZMAN")
                    .font(.system(size: 46, weight: .ultraLight, design: .rounded))
                    .tracking(10)
                    .foregroundStyle(Theme.primary)

            }

            Spacer(minLength: 52)

            // Game info
            VStack(spacing: 12) {
                infoRow(L10n.Home.info1)
                infoRow(L10n.Home.info2)
                infoRow(L10n.Home.info3)
                infoRow(L10n.Home.info4)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                Button {
                    vm.startNewGame()
                    withAnimation { showGame = true }
                } label: {
                    Text(L10n.Home.playButton)
                        .font(Theme.headline(17))
                        .foregroundStyle(Theme.felt)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: Theme.rMd).fill(Theme.valid))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 44)

            // Special cards guide
            HStack(spacing: 20) {
                specialCard("2", color: Theme.reset, desc: L10n.Home.resets)
                specialCard("7", color: Theme.low,   desc: L10n.Home.forcesLow)
                specialCard("10", color: Theme.burn, desc: L10n.Home.burnsPile)
            }
            .padding(.bottom, 32)
        }
        .overlay(alignment: .topTrailing) {
            Button { showRules = true } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.tertiary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.trailing, 16)
            .sheet(isPresented: $showRules) {
                RulesSheet()
                    .environmentObject(settings)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(settings.felt)
            }
        }
        .overlay(alignment: .topLeading) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.tertiary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.leading, 16)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(settings.felt)
            }
        }
    }

    private var cardFan: some View {
        HStack(spacing: -14) {
            fanCard("7", suit: .diamonds, rotation: -20)
            fanCard("10", suit: .spades,  rotation: -7)
            fanCard("A", suit: .hearts,   rotation: 7)
            fanCard("2", suit: .clubs,    rotation: 20)
        }
    }

    private func fanCard(_ rank: String, suit: Suit, rotation: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Theme.cardFace)
                .frame(width: 42, height: 60)
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            VStack(spacing: -2) {
                Text(rank).font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(suit.cardColor)
                Text(suit.symbol).font(.system(size: 10))
                    .foregroundStyle(suit.cardColor)
            }
            .offset(x: -7, y: -9)
        }
        .rotationEffect(.degrees(rotation))
    }

    private func infoRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("·").font(Theme.label(17)).foregroundStyle(Theme.secondary)
            Text(text).font(Theme.label(16)).foregroundStyle(Theme.secondary)
            Spacer()
        }
    }

    private func specialCard(_ rank: String, color: Color, desc: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(Theme.cardFace).frame(width: 34, height: 48)
                    .cShadow()
                Text(rank).font(.system(size: 13, weight: .bold)).foregroundStyle(color)
            }
            Text(desc).font(Theme.caption(13)).foregroundStyle(Theme.secondary)
        }
    }
}
