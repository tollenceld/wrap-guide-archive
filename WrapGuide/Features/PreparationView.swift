import SwiftUI

struct PreparationView: View {
    let coordinator: AppCoordinator
    @State private var selectedMode: GuidanceMode

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _selectedMode = State(initialValue: coordinator.mode)
    }

    var body: some View {
        FormPage(eyebrow: "prepare.eyebrow", title: "prepare.title", subtitle: "prepare.subtitle") {
            PreparationWorkspaceView(dimensions: coordinator.dimensions)
                .frame(height: 286)

            if let plan = coordinator.selectedPlan {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("prepare.paper")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryInk)
                        Text(plan.sheetSize.formatted())
                            .font(.title3.weight(.bold).monospacedDigit())
                    }
                    Spacer()
                    if plan.recommendsCutting {
                        StatusPill(title: "prepare.cut.short", systemImage: "scissors", tint: AppTheme.amber)
                    }
                    Button("prepare.changePaper") {
                        coordinator.presentedSheet = .customPaper
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.blue)
                }
                .studioSurface()
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("prepare.mode")
                    .font(.headline)

                HStack(spacing: 10) {
                    GuidanceModeCard(
                        mode: .handheld,
                        selected: selectedMode == .handheld,
                        action: { select(.handheld) }
                    )
                    GuidanceModeCard(
                        mode: .tabletop,
                        selected: selectedMode == .tabletop,
                        action: { select(.tabletop) }
                    )
                }

                Label(
                    selectedMode == .handheld ? "mode.handheld.detail" : "mode.tabletop.detail",
                    systemImage: selectedMode == .handheld ? "hand.raised.fill" : "iphone.gen3.radiowaves.left.and.right"
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryInk)
                .contentTransition(.opacity)
            }
            .studioSurface()

            HStack(spacing: 8) {
                ToolChip(icon: "shippingbox", title: "prepare.box")
                ToolChip(icon: "scissors", title: "prepare.scissors")
                ToolChip(icon: "bandage", title: "prepare.tape")
            }

            Button("prepare.begin") {
                AppHaptics.impact()
                coordinator.beginGuidance(mode: selectedMode)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("beginGuidanceButton")
        }
    }

    private func select(_ mode: GuidanceMode) {
        AppHaptics.selection()
        withAnimation(AppMotion.spatial) {
            selectedMode = mode
        }
    }
}

private struct GuidanceModeCard: View {
    let mode: GuidanceMode
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Image(systemName: mode == .handheld ? "iphone.gen3" : "iphone.gen3.radiowaves.left.and.right")
                        .font(.title2)
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? AppTheme.blue : AppTheme.secondaryInk.opacity(0.45))
                }
                Text(mode == .handheld ? "mode.handheld" : "mode.tabletop")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(selected ? AppTheme.blue : AppTheme.ink)
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .background(selected ? AppTheme.blue.opacity(0.08) : AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? AppTheme.blue : AppTheme.separator, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct ToolChip: View {
    let icon: String
    let title: LocalizedStringKey

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.secondaryInk)
            .labelStyle(.iconOnly)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.separator))
            .accessibilityLabel(title)
    }
}
