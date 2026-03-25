import SwiftUI

struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    section(L10n.Rules.Objective.title) {
                        rule(L10n.Rules.Objective.text)
                    }

                    section(L10n.Rules.Setup.title) {
                        rule(L10n.Rules.Setup.text1)
                        rule(L10n.Rules.Setup.text2)
                    }

                    section(L10n.Rules.Join.title) {
                        joinRule(L10n.Rules.Join.text1)
                        rule(L10n.Rules.Join.text2)
                    }

                    section(L10n.Rules.Turn.title) {
                        rule(L10n.Rules.Turn.text1)
                        rule(L10n.Rules.Turn.text2)
                        rule(L10n.Rules.Turn.text3)
                    }

                    section(L10n.Rules.Zones.title) {
                        rule(L10n.Rules.Zones.text1)
                        rule(L10n.Rules.Zones.text2)
                    }

                    section(L10n.Rules.Special.title) {
                        specialRule("2", color: Theme.reset, L10n.Rules.Special.text2)
                        specialRule("7", color: Theme.low,   L10n.Rules.Special.text7)
                        specialRule("10", color: Theme.burn, L10n.Rules.Special.text10)
                    }

                    section(L10n.Rules.Burn.title) {
                        rule(L10n.Rules.Burn.text)
                    }

                    section(L10n.Rules.Peek.title) {
                        rule(L10n.Rules.Peek.text1)
                        rule(L10n.Rules.Peek.text2)
                    }

                    section(L10n.Rules.Dig.title) {
                        digRule(L10n.Rules.Dig.text1)
                        rule(L10n.Rules.Dig.text2)
                    }

                    section(L10n.Rules.Win.title) {
                        rule(L10n.Rules.Win.text)
                    }
                }
                .padding(24)
            }
            .background(Theme.felt.ignoresSafeArea())
            .navigationTitle(L10n.Rules.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Rules.done) { dismiss() }
                        .font(Theme.label(15))
                        .foregroundStyle(Theme.valid)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(Theme.caption(10))
                .tracking(3)
                .foregroundStyle(Theme.tertiary)
            content()
        }
    }

    private func rule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.tertiary)
                .frame(width: 4, height: 4)
                .padding(.top, 7)
            Text(text)
                .font(Theme.label(14))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func joinRule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "link")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.hint)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.hint.opacity(0.18)))
                .padding(.top, 2)
            Text(text)
                .font(Theme.label(14))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func digRule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.reset)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.reset.opacity(0.18)))
                .padding(.top, 2)
            Text(text)
                .font(Theme.label(14))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func specialRule(_ rank: String, color: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(rank)
                .font(Theme.caption(10))
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(color.opacity(0.18)))
                .padding(.top, 2)
            Text(text)
                .font(Theme.label(14))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
