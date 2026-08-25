import SwiftUI

struct AppFlowView: View {
    @State private var coordinator = PlannerCoordinator()

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack {
            Group {
                switch coordinator.route {
                case .input:
                    PlannerInputView(coordinator: coordinator)
                case .results:
                    PlannerResultsView(coordinator: coordinator)
                }
            }
            .animation(AppMotion.standard, value: coordinator.route)
        }
        .tint(AppTheme.blue)
        .sheet(item: $coordinator.presentedSheet) { destination in
            switch destination {
            case .customPaper:
                CustomPaperSheet(coordinator: coordinator)
            }
        }
    }
}
