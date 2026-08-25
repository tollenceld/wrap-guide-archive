import Foundation
import Observation

@MainActor
@Observable
final class PlannerCoordinator {
    var route: PlannerRoute = .input
    var dimensions = BoxDimensions.phoneBox
    var selectedStrategy: PaperStrategy = .easyWrap
    var presentedSheet: PlannerSheet?
    private(set) var plans: [PaperPlan] = []

    private let planner: any PaperPlanning

    init(planner: any PaperPlanning = PaperPlanner()) {
        self.planner = planner
    }

    var selectedPlan: PaperPlan? {
        plans.first { $0.strategy == selectedStrategy } ?? plans.first
    }

    func calculate() {
        guard dimensions.isValid else { return }
        dimensions = dimensions.sorted
        plans = planner.recommend(for: dimensions)
        selectedStrategy = .easyWrap
        route = .results
    }

    func select(_ strategy: PaperStrategy) {
        guard strategy != .custom else { return }
        selectedStrategy = strategy
    }

    func evaluateCustomPaper(_ sheet: PaperSpec) -> PaperPlan {
        planner.evaluate(custom: sheet, for: dimensions)
    }

    func editDimensions() {
        route = .input
    }

    func reset() {
        dimensions = .phoneBox
        plans = []
        selectedStrategy = .easyWrap
        route = .input
    }
}
