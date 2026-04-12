import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Gameplay
                    section(L10n.Settings.sectionGameplay) {
                        toggle(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: Theme.reset,
                            title: L10n.Settings.digTitle,
                            subtitle: L10n.Settings.digSubtitle,
                            isOn: $settings.digEnabled
                        )
                        Divider().background(Theme.border).padding(.leading, 52)
                        toggle(
                            icon: "eye",
                            iconColor: Theme.secondary,
                            title: L10n.Settings.peekTitle,
                            subtitle: L10n.Settings.peekSubtitle,
                            isOn: $settings.pilePeekEnabled
                        )
                        Divider().background(Theme.border).padding(.leading, 52)
                        toggle(
                            icon: "waveform",
                            iconColor: Theme.hint,
                            title: L10n.Settings.hapticsTitle,
                            subtitle: L10n.Settings.hapticsSubtitle,
                            isOn: $settings.hapticsEnabled
                        )
                    }

                    // MARK: - Table colour
                    section(L10n.Settings.sectionTableColor) {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: Theme.isPad ? 4 : 3), spacing: 12) {
                            ForEach(FeltColor.allCases, id: \.rawValue) { color in
                                colorSwatch(color)
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(24)
            }
            .background(settings.felt.ignoresSafeArea())
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Settings.done) { dismiss() }
                        .font(Theme.label(15))
                        .foregroundStyle(Theme.valid)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(Theme.caption(11))
                .tracking(3)
                .foregroundStyle(Theme.tertiary)
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.rMd)
                    .fill(settings.surface)
                    .overlay(RoundedRectangle(cornerRadius: Theme.rMd)
                        .strokeBorder(Theme.border, lineWidth: 0.5))
            )
        }
    }

    private func toggle(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.label(15))
                    .foregroundStyle(Theme.primary)
                Text(subtitle)
                    .font(Theme.caption(13))
                    .foregroundStyle(Theme.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.valid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func colorSwatch(_ color: FeltColor) -> some View {
        let selected = settings.feltColor == color
        return Button {
            settings.feltColor = color
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: Theme.rSm)
                    .fill(color.felt)
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.rSm)
                            .strokeBorder(
                                selected ? Theme.valid : Color.white.opacity(0.08),
                                lineWidth: selected ? 2 : 0.5
                            )
                    )
                    .overlay(
                        selected
                            ? Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.valid)
                            : nil
                    )
                Text(color.label)
                    .font(Theme.caption(12))
                    .foregroundStyle(selected ? Theme.valid : Theme.tertiary)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }
}
