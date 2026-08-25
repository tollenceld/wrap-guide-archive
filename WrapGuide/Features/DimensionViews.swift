import SwiftUI

struct ManualMeasurementView: View {
    let coordinator: AppCoordinator
    @State private var dimensions = BoxDimensions.phoneBox

    var body: some View {
        FormPage(
            eyebrow: "manual.eyebrow",
            title: "manual.title",
            subtitle: coordinator.cameraDenied ? "manual.cameraDenied" : "manual.subtitle"
        ) {
            StudioBoxView(dimensions: dimensions, showDimensions: true)
                .frame(height: 238)
                .studioSurface(padding: 6)

            DimensionEditor(dimensions: $dimensions)
                .studioSurface()

            if coordinator.cameraDenied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("manual.openSettings", systemImage: "gear")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Button("action.continue") {
                AppHaptics.selection()
                coordinator.acceptManualDimensions(dimensions)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!dimensions.isValid)
            .accessibilityIdentifier("manualContinueButton")
        }
    }
}

struct DimensionConfirmationView: View {
    let coordinator: AppCoordinator
    @State private var dimensions: BoxDimensions

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _dimensions = State(initialValue: coordinator.dimensions)
    }

    private var measurement: MeasurementResult? { coordinator.session.measurement }

    var body: some View {
        FormPage(eyebrow: "confirm.eyebrow", title: "confirm.title", subtitle: "confirm.subtitle") {
            VStack(spacing: 0) {
                StudioBoxView(dimensions: dimensions, showDimensions: true)
                    .frame(height: 252)

                HStack(spacing: 8) {
                    StatusPill(
                        title: measurement?.source.localizedKey ?? "measurement.source.manual",
                        systemImage: measurement?.source == .automatic ? "viewfinder.circle.fill" : "hand.tap.fill",
                        tint: AppTheme.blue
                    )

                    if let measurement {
                        StatusPill(
                            title: measurement.confidence >= 0.85 ? "measurement.confidence.good" : "measurement.confidence.review",
                            systemImage: measurement.confidence >= 0.85 ? "checkmark.seal.fill" : "exclamationmark.circle.fill",
                            tint: measurement.confidence >= 0.85 ? AppTheme.cyan : AppTheme.amber
                        )
                    }
                }
                .padding(.bottom, 16)
            }
            .studioSurface(padding: 8)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("confirm.adjust")
                        .font(.headline)
                    Spacer()
                    Text(dimensions.formatted())
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.blue)
                }

                DimensionEditor(dimensions: $dimensions)
            }
            .studioSurface()
            .onChange(of: dimensions) { _, newValue in
                coordinator.updateDimensions(newValue)
            }

            Button("confirm.paper") {
                AppHaptics.selection()
                coordinator.updateDimensions(dimensions)
                coordinator.showPaperPlans()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!dimensions.isValid)
            .accessibilityIdentifier("confirmDimensionsButton")
        }
    }
}

struct DimensionEditor: View {
    @Binding var dimensions: BoxDimensions
    @AppStorage("unitPreference") private var unitPreference = LengthUnitPreference.automatic.rawValue

    private var unit: LengthUnitPreference { LengthUnitPreference(rawValue: unitPreference) ?? .automatic }
    private var divisor: Double { unit.resolved == .imperial ? 25.4 : 10 }
    private var suffix: String { unit.resolved == .imperial ? "in" : "cm" }

    var body: some View {
        VStack(spacing: 0) {
            DimensionField(title: "dimension.length", axis: "L", tint: AppTheme.blue, value: binding(\.lengthMM), suffix: suffix)
            Divider().overlay(AppTheme.separator)
            DimensionField(title: "dimension.width", axis: "W", tint: AppTheme.cyan, value: binding(\.widthMM), suffix: suffix)
            Divider().overlay(AppTheme.separator)
            DimensionField(title: "dimension.height", axis: "H", tint: AppTheme.amber, value: binding(\.heightMM), suffix: suffix)
        }
    }

    private func binding(_ keyPath: WritableKeyPath<BoxDimensions, Double>) -> Binding<Double> {
        Binding(
            get: { dimensions[keyPath: keyPath] / divisor },
            set: { dimensions[keyPath: keyPath] = $0 * divisor }
        )
    }
}

private struct DimensionField: View {
    let title: LocalizedStringKey
    let axis: String
    let tint: Color
    @Binding var value: Double
    let suffix: String

    var body: some View {
        HStack(spacing: 12) {
            Text(axis)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
            Spacer()
            TextField("0.0", value: $value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.bold).monospacedDigit())
                .frame(width: 92)
                .accessibilityLabel(title)
            Text(suffix)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.vertical, 13)
    }
}

struct FormPage<Content: View>: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        StudioPage {
            VStack(alignment: .leading, spacing: 20) {
                StudioHeader(eyebrow: eyebrow, title: title, subtitle: subtitle)
                content
            }
        }
    }
}

private extension MeasurementSource {
    var localizedKey: LocalizedStringKey {
        switch self {
        case .automatic, .simulated: "measurement.source.automatic"
        case .assisted: "measurement.source.assisted"
        case .manual: "measurement.source.manual"
        }
    }
}
