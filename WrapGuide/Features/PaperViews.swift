import SwiftUI

struct PlannerInputView: View {
    let coordinator: PlannerCoordinator
    @AppStorage("unitPreference") private var unitRaw = LengthUnitPreference.automatic.rawValue

    private var unit: LengthUnitPreference {
        LengthUnitPreference(rawValue: unitRaw) ?? .automatic
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PlannerHeader(
                    eyebrow: "input.eyebrow",
                    title: "input.title",
                    subtitle: "input.subtitle"
                )

                UnitPicker(selection: $unitRaw)

                BoxDimensionPreview(dimensions: coordinator.dimensions)
                    .frame(height: 178)

                DimensionInputGroup(dimensions: $coordinator.dimensions, unit: unit)

                Label("input.local", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FixedActionBar {
                Button("input.calculate") {
                    coordinator.calculate()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!coordinator.dimensions.isValid)
                .accessibilityIdentifier("plannerCalculateButton")
            }
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .foregroundStyle(AppTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct PlannerResultsView: View {
    let coordinator: PlannerCoordinator
    @AppStorage("unitPreference") private var unitRaw = LengthUnitPreference.automatic.rawValue

    private var unit: LengthUnitPreference {
        LengthUnitPreference(rawValue: unitRaw) ?? .automatic
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top, spacing: 14) {
                    PlannerHeader(
                        eyebrow: "results.eyebrow",
                        title: "results.title",
                        subtitle: "results.subtitle"
                    )
                    Button("results.edit") { coordinator.editDimensions() }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("editDimensionsButton")
                }

                StrategySelector(
                    selected: coordinator.selectedStrategy,
                    onSelect: coordinator.select
                )

                if let plan = coordinator.selectedPlan {
                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(plan.strategy.titleKey)
                                    .font(.title3.weight(.bold))
                                Text(plan.strategy.detailKey)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryInk)
                            }
                            Spacer()
                            StatusPill(title: plan.difficulty.titleKey, tint: plan.difficulty.tint)
                        }

                        PaperLayoutDiagram(plan: plan, dimensions: coordinator.dimensions)
                            .frame(height: 288)

                        Text(plan.cutSize.formatted(unit: unit))
                            .font(.system(.title, design: .rounded, weight: .bold).monospacedDigit())
                            .contentTransition(.numericText())

                        HStack(spacing: 0) {
                            PlanFact(label: "results.box", value: coordinator.dimensions.formatted(unit: unit))
                            Divider().frame(height: 42)
                            PlanFact(label: "results.overlap", value: plan.margins.seamOverlapMM.formattedLength(unit: unit))
                        }
                    }
                    .plannerSurface(padding: 16, radius: 26)

                    VStack(alignment: .leading, spacing: 10) {
                        ResultLine(label: "results.endAllowance", value: plan.margins.endAllowanceMM.formattedLength(unit: unit))
                        ResultLine(label: "results.orientation", value: plan.orientation.titleKey)
                    }
                    .plannerSurface()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 22)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FixedActionBar {
                Button("results.custom") {
                    coordinator.presentedSheet = .customPaper
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("customPaperButton")
            }
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .foregroundStyle(AppTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CustomPaperSheet: View {
    @Environment(\.dismiss) private var dismiss
    let coordinator: PlannerCoordinator
    @State private var sheet: PaperSpec
    @AppStorage("unitPreference") private var unitRaw = LengthUnitPreference.automatic.rawValue

    init(coordinator: PlannerCoordinator) {
        self.coordinator = coordinator
        let suggested = coordinator.selectedPlan?.cutSize ?? PaperSpec(widthMM: 430, heightMM: 370)
        _sheet = State(initialValue: PaperSpec(widthMM: suggested.heightMM, heightMM: suggested.widthMM))
    }

    private var unit: LengthUnitPreference {
        LengthUnitPreference(rawValue: unitRaw) ?? .automatic
    }

    private var result: PaperPlan {
        coordinator.evaluateCustomPaper(sheet)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    PlannerHeader(
                        eyebrow: "custom.eyebrow",
                        title: "custom.title",
                        subtitle: "custom.subtitle"
                    )

                    PaperInputGroup(sheet: $sheet, unit: unit)

                    PaperLayoutDiagram(plan: result, dimensions: coordinator.dimensions)
                        .frame(height: 250)
                        .plannerSurface(padding: 10, radius: 24)

                    CustomFitResult(plan: result, unit: unit)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FixedActionBar {
                    Button("custom.done") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("customPaperCloseButton")
                }
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .foregroundStyle(AppTheme.ink)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
    }
}

private struct UnitPicker: View {
    @Binding var selection: String

    var body: some View {
        Picker("unit.title", selection: $selection) {
            ForEach(LengthUnitPreference.allCases) { unit in
                Text(unit.titleKey).tag(unit.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("unitPicker")
    }
}

private struct DimensionInputGroup: View {
    @Binding var dimensions: BoxDimensions
    let unit: LengthUnitPreference

    var body: some View {
        VStack(spacing: 0) {
            MeasurementField(label: "dimension.length", axis: "L", tint: AppTheme.blue, value: binding(\.lengthMM), unit: unit)
            Divider()
            MeasurementField(label: "dimension.width", axis: "W", tint: AppTheme.cyan, value: binding(\.widthMM), unit: unit)
            Divider()
            MeasurementField(label: "dimension.height", axis: "H", tint: AppTheme.amber, value: binding(\.heightMM), unit: unit)
        }
        .plannerSurface(padding: 0)
    }

    private func binding(_ keyPath: WritableKeyPath<BoxDimensions, Double>) -> Binding<Double> {
        Binding(
            get: { dimensions[keyPath: keyPath] },
            set: { dimensions[keyPath: keyPath] = $0 }
        )
    }
}

private struct PaperInputGroup: View {
    @Binding var sheet: PaperSpec
    let unit: LengthUnitPreference

    var body: some View {
        VStack(spacing: 0) {
            MeasurementField(label: "custom.width", axis: "W", tint: AppTheme.blue, value: $sheet.widthMM, unit: unit)
            Divider()
            MeasurementField(label: "custom.height", axis: "H", tint: AppTheme.cyan, value: $sheet.heightMM, unit: unit)
        }
        .plannerSurface(padding: 0)
    }
}

private struct MeasurementField: View {
    let label: LocalizedStringKey
    let axis: String
    let tint: Color
    @Binding var value: Double
    let unit: LengthUnitPreference

    private var divisor: Double { unit.resolved == .imperial ? 25.4 : 10 }
    private var suffix: String { unit.resolved == .imperial ? "in" : "cm" }

    private var displayValue: Binding<Double> {
        Binding(get: { value / divisor }, set: { value = $0 * divisor })
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(axis)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
            Spacer()
            TextField("0.0", value: displayValue, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.bold).monospacedDigit())
                .frame(width: 94)
                .accessibilityLabel(label)
            Text(suffix)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
    }
}

private struct StrategySelector: View {
    let selected: PaperStrategy
    let onSelect: (PaperStrategy) -> Void

    var body: some View {
        HStack(spacing: 8) {
            strategyButton(.easyWrap)
            strategyButton(.justFit)
        }
        .padding(4)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(AppTheme.separator))
    }

    private func strategyButton(_ strategy: PaperStrategy) -> some View {
        Button {
            onSelect(strategy)
        } label: {
            VStack(spacing: 2) {
                Text(strategy.titleKey).font(.subheadline.weight(.bold))
                Text(strategy.shortDetailKey).font(.caption2)
            }
            .foregroundStyle(selected == strategy ? .white : AppTheme.secondaryInk)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(selected == strategy ? AppTheme.blue : .clear, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("paperPlan_\(strategy.rawValue)")
        .accessibilityAddTraits(selected == strategy ? .isSelected : [])
    }
}

private struct CustomFitResult: View {
    let plan: PaperPlan
    let unit: LengthUnitPreference

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("custom.result")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(plan.difficulty.titleKey)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(plan.difficulty.tint)
                        .accessibilityIdentifier("customPaperFitStatus")
                }
                Spacer()
                if plan.isFeasible && plan.rotationDegrees != 0 {
                    Label(String(format: "%.0f°", plan.rotationDegrees), systemImage: "rotate.right")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.blue)
                }
            }

            ResultLine(
                label: plan.isFeasible ? "custom.cutSize" : "custom.minimum",
                value: plan.cutSize.formatted(unit: unit)
            )
            if plan.isFeasible {
                ResultLine(label: "results.overlap", value: plan.margins.seamOverlapMM.formattedLength(unit: unit))
                if plan.recommendsCutting {
                    Label("custom.cutRecommended", systemImage: "scissors")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.amber)
                }
            } else {
                Text("custom.insufficient.detail")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .plannerSurface()
    }
}

private struct PlanFact: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}

private struct ResultLine: View {
    let label: LocalizedStringKey
    let value: LocalizedStringKey

    init(label: LocalizedStringKey, value: LocalizedStringKey) {
        self.label = label
        self.value = value
    }

    init(label: LocalizedStringKey, value: String) {
        self.label = label
        self.value = LocalizedStringKey(value)
    }

    var body: some View {
        HStack {
            Text(label).foregroundStyle(AppTheme.secondaryInk)
            Spacer()
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private extension LengthUnitPreference {
    var titleKey: LocalizedStringKey {
        switch self {
        case .automatic: "unit.automatic"
        case .metric: "unit.metric"
        case .imperial: "unit.imperial"
        }
    }
}

extension PaperStrategy {
    var titleKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "strategy.easy"
        case .justFit: "strategy.just"
        case .custom: "strategy.custom"
        }
    }

    var detailKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "strategy.easy.detail"
        case .justFit: "strategy.just.detail"
        case .custom: "strategy.custom.detail"
        }
    }

    var shortDetailKey: LocalizedStringKey {
        switch self {
        case .easyWrap: "strategy.easy.short"
        case .justFit: "strategy.just.short"
        case .custom: "strategy.custom.short"
        }
    }
}

extension PaperDifficulty {
    var titleKey: LocalizedStringKey {
        switch self {
        case .roomy: "difficulty.roomy"
        case .comfortable: "difficulty.comfortable"
        case .precise: "difficulty.precise"
        case .insufficient: "difficulty.insufficient"
        }
    }

    var tint: Color {
        switch self {
        case .roomy, .comfortable: AppTheme.cyan
        case .precise: AppTheme.amber
        case .insufficient: AppTheme.danger
        }
    }
}

private extension BoxOrientation {
    var titleKey: LocalizedStringKey {
        switch self {
        case .longAxis: "orientation.long"
        case .shortAxis: "orientation.short"
        }
    }
}

private extension Double {
    func formattedLength(unit: LengthUnitPreference) -> String {
        unit.resolved == .imperial
            ? String(format: "%.1f in", self / 25.4)
            : String(format: "%.1f cm", self / 10)
    }
}
