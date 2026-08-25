import SwiftUI

struct CompletionView: View {
    let coordinator: AppCoordinator
    @State private var revealed = false

    var body: some View {
        StudioPage {
            VStack(spacing: 0) {
                StatusPill(title: "complete.status", systemImage: "checkmark", tint: AppTheme.cyan)
                    .padding(.top, 4)

                Text("complete.title")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .padding(.top, 18)
                Text("complete.subtitle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .padding(.top, 7)

                CompletedGiftView()
                    .frame(height: 300)
                    .padding(.top, 4)

                if let plan = coordinator.selectedPlan {
                    HStack(spacing: 0) {
                        ResultMetric(label: "complete.box", value: coordinator.dimensions.formatted(), icon: "shippingbox")
                        Divider().frame(height: 50).overlay(AppTheme.separator)
                        ResultMetric(label: "complete.paper", value: plan.sheetSize.formatted(), icon: "rectangle.portrait")
                    }
                    .studioSurface(padding: 14, radius: 20)

                    HStack(spacing: 0) {
                        ResultMetric(label: "complete.plan", value: plan.strategy.completionTitle, icon: "sparkles")
                        Divider().frame(height: 50).overlay(AppTheme.separator)
                        ResultMetric(
                            label: "complete.utilization",
                            value: String(format: "%.0f%%", (1 - plan.wasteRatio) * 100),
                            icon: "leaf"
                        )
                    }
                    .studioSurface(padding: 14, radius: 20)
                    .padding(.top, 10)
                }

                Button("complete.another") {
                    AppHaptics.selection()
                    coordinator.startAnother()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 22)
                .accessibilityIdentifier("wrapAnotherButton")
            }
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 12)
        }
        .onAppear {
            AppHaptics.success()
            withAnimation(AppMotion.settle) {
                revealed = true
            }
        }
    }
}

private struct ResultMetric: View {
    let label: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.66)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

private extension PaperStrategy {
    var completionTitle: String {
        switch self {
        case .easyWrap: String(localized: "paper.easy.short")
        case .justFit: String(localized: "paper.just.short")
        case .custom: String(localized: "paper.custom.short")
        }
    }
}
