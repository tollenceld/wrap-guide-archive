import SwiftUI

struct PaperPlansView: View {
    let coordinator: AppCoordinator
    @State private var selectedStrategy: PaperStrategy = .easyWrap

    private var selectedPlan: PaperPlan? {
        coordinator.plans.first { $0.strategy == selectedStrategy }
            ?? coordinator.plans.first
    }

    var body: some View {
        FormPage(eyebrow: "paper.eyebrow", title: "paper.title", subtitle: "paper.subtitle") {
            if let selectedPlan {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedPlan.strategy.titleKey)
                            .font(.title2.bold())
                        Text(selectedPlan.strategy.subtitleKey)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .lineLimit(2)
                    }
                    Spacer()
                    StatusPill(
                        title: selectedPlan.difficulty.localizedKey,
                        systemImage: selectedPlan.isFeasible ? "checkmark.circle.fill" : "xmark.octagon.fill",
                        tint: selectedPlan.isFeasible ? AppTheme.cyan : AppTheme.danger
                    )
                }

                PaperPlanScene(plan: selectedPlan, dimensions: coordinator.dimensions)
                    .frame(height: 430)
                    .padding(.horizontal, -6)
                    .contentTransition(.numericText())

                PaperPlanFactBar(plan: selectedPlan, dimensions: coordinator.dimensions)

                HStack(spacing: 7) {
                    ForEach(coordinator.plans) { plan in
                        PaperPlanChoice(
                            plan: plan,
                            selected: plan.strategy == selectedStrategy
                        ) {
                            AppHaptics.selection()
                            withAnimation(AppMotion.spatial) {
                                selectedStrategy = plan.strategy
                            }
                        }
                    }

                    Button {
                        coordinator.presentedSheet = .customPaper
                    } label: {
                        VStack(spacing: 5) {
                            PaperPlanGlyph(strategy: .custom)
                            Text("paper.custom.short")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text("paper.custom.benefit")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondaryInk.opacity(0.76))
                                .lineLimit(1)
                        }
                        .foregroundStyle(AppTheme.secondaryInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 108)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.separator))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("customPaperButton")
                }
                .dynamicTypeSize(...DynamicTypeSize.xLarge)

                Button {
                    AppHaptics.impact()
                    coordinator.selectPaperPlan(selectedPlan)
                } label: {
                    Label("paper.usePlan", systemImage: "arrow.right")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("paperPlan_\(selectedPlan.strategy.rawValue)")
            }
        }
    }
}

private struct PaperPlanChoice: View {
    let plan: PaperPlan
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                PaperPlanGlyph(strategy: plan.strategy, selected: selected)
                Text(plan.strategy.shortTitleKey)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(plan.strategy.benefitKey)
                    .font(.caption2)
                    .foregroundStyle(selected ? AppTheme.blue.opacity(0.78) : AppTheme.secondaryInk.opacity(0.76))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? AppTheme.blue : AppTheme.secondaryInk)
            .frame(maxWidth: .infinity)
            .frame(height: 108)
            .background(selected ? AppTheme.blue.opacity(0.075) : AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? AppTheme.blue : AppTheme.separator, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(AppTheme.blue, in: Circle())
                        .offset(x: -7, y: 7)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct PlanMetric: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CustomPaperView: View {
    @Environment(\.dismiss) private var dismiss
    let coordinator: AppCoordinator
    @State private var widthCM = 50.0
    @State private var heightCM = 70.0

    private var sheet: PaperSpec { PaperSpec(widthMM: widthCM * 10, heightMM: heightCM * 10) }
    private var result: PaperPlan { coordinator.evaluateCustomPaper(sheet) }

    var body: some View {
        NavigationStack {
            StudioPage {
                VStack(alignment: .leading, spacing: 18) {
                    StudioHeader(eyebrow: "paper.eyebrow", title: "custom.title", subtitle: "custom.subtitle")

                    HStack(spacing: 12) {
                        PaperDimensionField(title: "custom.width", value: $widthCM)
                        PaperDimensionField(title: "custom.height", value: $heightCM)
                    }

                    PaperPlanScene(plan: result, dimensions: coordinator.dimensions)
                        .frame(height: 400)
                        .studioSurface(padding: 8)

                    CustomFitResult(plan: result)

                    Button("custom.use") {
                        AppHaptics.impact()
                        coordinator.selectPaperPlan(result)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!result.isFeasible)
                }
            }
            .navigationTitle("custom.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct PaperDimensionField: View {
    let title: LocalizedStringKey
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryInk)
            HStack(spacing: 4) {
                TextField("0.0", value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.bold).monospacedDigit())
                Text("cm")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .studioSurface(padding: 14, radius: 18)
    }
}

private struct CustomFitResult: View {
    let plan: PaperPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusPill(
                    title: plan.difficulty.localizedKey,
                    systemImage: plan.isFeasible ? "checkmark.seal.fill" : "xmark.octagon.fill",
                    tint: plan.isFeasible ? AppTheme.cyan : AppTheme.danger
                )
                Spacer()
                if plan.rotationDegrees != 0 {
                    Label(String(format: "%.0f°", plan.rotationDegrees), systemImage: "rotate.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.blue)
                }
            }

            if plan.isFeasible {
                DetailRow(label: "custom.cutSize", value: plan.cutSize.formatted())
                DetailRow(label: "custom.remaining", value: String(format: "%.0f%%", plan.wasteRatio * 100))
                if plan.recommendsCutting {
                    Label("custom.cutRecommended", systemImage: "scissors")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.amber)
                }
            } else {
                Text("custom.insufficient.detail")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .studioSurface()
    }
}

struct DetailRow: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(AppTheme.secondaryInk)
            Spacer()
            Text(value).fontWeight(.semibold).monospacedDigit()
        }
        .font(.subheadline)
    }
}

private extension PaperStrategy {
    var titleKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "paper.easy.title"
        case .justFit: "paper.just.title"
        case .custom: "paper.custom.title"
        }
    }

    var shortTitleKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "paper.easy.short"
        case .justFit: "paper.just.short"
        case .custom: "paper.custom.short"
        }
    }

    var subtitleKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "paper.easy.subtitle"
        case .justFit: "paper.just.subtitle"
        case .custom: "paper.custom.subtitle"
        }
    }

    var benefitKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "paper.easy.benefit"
        case .justFit: "paper.just.benefit"
        case .custom: "paper.custom.benefit"
        }
    }
}
