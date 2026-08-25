import SwiftData
import SwiftUI

struct AppFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = AppCoordinator()

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack {
            ZStack {
                AppTheme.canvas.ignoresSafeArea()
                stageContent
                    .id(coordinator.stage)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        )
                    )
            }
            .animation(AppMotion.standard, value: coordinator.stage)
            .toolbar {
                if coordinator.stage != .home && coordinator.stage != .guidance && coordinator.stage != .scan {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            coordinator.goHome()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel(Text("action.close"))
                    }
                }
                if coordinator.stage == .home {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            coordinator.presentedSheet = .settings
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel(Text("settings.title"))
                    }
                }
            }
        }
        .tint(AppTheme.blue)
        .sheet(item: $coordinator.presentedSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .customPaper:
                CustomPaperView(coordinator: coordinator)
            }
        }
        .alert("error.title", isPresented: Binding(
            get: { coordinator.errorMessage != nil },
            set: { if !$0 { coordinator.errorMessage = nil } }
        )) {
            Button("action.ok", role: .cancel) { coordinator.errorMessage = nil }
        } message: {
            Text(coordinator.errorMessage ?? "")
        }
        .task {
            coordinator.attach(repository: SwiftDataSessionRepository(context: modelContext))
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch coordinator.stage {
        case .home:
            HomeView(coordinator: coordinator)
        case .scan:
            ScanView(coordinator: coordinator)
        case .manualMeasurement:
            ManualMeasurementView(coordinator: coordinator)
        case .confirmDimensions:
            DimensionConfirmationView(coordinator: coordinator)
        case .paperPlans:
            PaperPlansView(coordinator: coordinator)
        case .preparation:
            PreparationView(coordinator: coordinator)
        case .guidance:
            GuidanceView(coordinator: coordinator)
        case .completed:
            CompletionView(coordinator: coordinator)
        }
    }
}
