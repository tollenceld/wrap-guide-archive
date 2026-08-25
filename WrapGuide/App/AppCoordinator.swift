import Foundation
import Observation

enum SheetDestination: String, Identifiable {
    case settings
    case customPaper

    var id: String { rawValue }
}

@MainActor
@Observable
final class AppCoordinator {
    private(set) var session = WrapSession.new()
    private(set) var plans: [PaperPlan] = []
    var presentedSheet: SheetDestination?
    var cameraDenied = false
    var errorMessage: String?

    private let planner: any PaperPlanning
    private let cameraPermission: any CameraPermissionProviding
    private var repository: (any SessionRepository)?

    init(
        planner: any PaperPlanning = PaperPlanner(),
        cameraPermission: any CameraPermissionProviding = SystemCameraPermissionService()
    ) {
        self.planner = planner
        self.cameraPermission = cameraPermission
    }

    var stage: FlowStage { session.stage }
    var dimensions: BoxDimensions { session.dimensions ?? .phoneBox }
    var selectedPlan: PaperPlan? { session.selectedPaperPlan }
    var currentStep: Int { session.currentStep }
    var mode: GuidanceMode { session.guidanceMode }
    var hasResumableSession: Bool { session.stage != .home && session.stage != .completed }

    func attach(repository: any SessionRepository) {
        guard self.repository == nil else { return }
        self.repository = repository
        do {
            #if DEBUG
            if configureUIPreviewIfRequested() {
                try repository.clear()
                return
            }
            #endif
            if ProcessInfo.processInfo.arguments.contains("-UITesting") {
                try repository.clear()
                session = .new()
                return
            }
            if let stored = try repository.loadActive(), stored.stage != .completed {
                session = stored
                if let dimensions = stored.dimensions {
                    plans = planner.recommend(for: dimensions)
                }
            }
        } catch {
            errorMessage = String(localized: "error.restore")
        }
    }

    func beginNewWrap() async {
        session = .new()
        plans = []
        cameraDenied = false
        let authorization = await cameraPermission.request()
        switch authorization {
        case .authorized:
            transition(to: .scan)
        case .denied, .restricted:
            cameraDenied = true
            transition(to: .manualMeasurement)
        }
    }

    func useManualMeasurement() {
        transition(to: .manualMeasurement)
    }

    func acceptMeasurement(_ result: MeasurementResult) {
        session.measurement = result
        session.dimensions = result.dimensions.sorted
        plans = planner.recommend(for: result.dimensions)
        transition(to: .confirmDimensions)
    }

    func acceptManualDimensions(_ dimensions: BoxDimensions) {
        let result = MeasurementResult(
            dimensions: dimensions.sorted,
            boxPose: .identity,
            confidence: 1,
            source: .manual,
            diagnostics: []
        )
        acceptMeasurement(result)
    }

    func updateDimensions(_ dimensions: BoxDimensions) {
        guard dimensions.isValid else { return }
        session.dimensions = dimensions.sorted
        if var measurement = session.measurement {
            measurement.dimensions = dimensions.sorted
            measurement.source = .assisted
            session.measurement = measurement
        }
        plans = planner.recommend(for: dimensions)
        persist()
    }

    func showPaperPlans() {
        plans = planner.recommend(for: dimensions)
        transition(to: .paperPlans)
    }

    func selectPaperPlan(_ plan: PaperPlan) {
        guard plan.isFeasible else { return }
        session.selectedPaperPlan = plan
        session.actualPaper = plan.sheetSize
        transition(to: .preparation)
    }

    func evaluateCustomPaper(_ sheet: PaperSpec) -> PaperPlan {
        planner.evaluate(custom: sheet, for: dimensions)
    }

    func setActualPaper(_ sheet: PaperSpec) {
        guard sheet.isValid else { return }
        let evaluated = planner.evaluate(custom: sheet, for: dimensions)
        session.actualPaper = sheet
        session.selectedPaperPlan = evaluated
        persist()
    }

    func beginGuidance(mode: GuidanceMode) {
        session.guidanceMode = mode
        session.currentStep = min(max(0, session.currentStep), StandardBoxWrapMethod().steps.count - 1)
        transition(to: .guidance)
    }

    func nextGuidanceStep() {
        let finalIndex = StandardBoxWrapMethod().steps.count - 1
        if session.currentStep >= finalIndex {
            transition(to: .completed)
        } else {
            session.currentStep += 1
            persist()
        }
    }

    func previousGuidanceStep() {
        session.currentStep = max(0, session.currentStep - 1)
        persist()
    }

    func resumeGuidance() {
        transition(to: session.stage == .guidance ? .guidance : session.stage)
    }

    func goHome() {
        session.stage = .home
        persist()
    }

    func startAnother() {
        do { try repository?.clear() } catch { errorMessage = String(localized: "error.save") }
        session = .new()
        plans = []
    }

    func abandonSession() {
        do { try repository?.clear() } catch { errorMessage = String(localized: "error.save") }
        session = .new()
        plans = []
    }

    private func transition(to stage: FlowStage) {
        session.stage = stage
        session.updatedAt = .now
        persist()
    }

    private func persist() {
        session.updatedAt = .now
        do {
            try repository?.save(session)
        } catch {
            errorMessage = String(localized: "error.save")
        }
    }

    #if DEBUG
    private func configureUIPreviewIfRequested() -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        let previewPaper = arguments.contains("-UIPreviewPaperPlans")
        let previewGuidance = arguments.contains("-UIPreviewGuidance")
        guard previewPaper || previewGuidance else { return false }

        let dimensions = BoxDimensions.phoneBox
        let measurement = MeasurementResult(
            dimensions: dimensions,
            boxPose: .identity,
            confidence: 0.94,
            source: .simulated,
            diagnostics: []
        )
        let previewPlans = planner.recommend(for: dimensions)
        session = .new()
        session.dimensions = dimensions
        session.measurement = measurement
        plans = previewPlans

        if previewGuidance, let plan = previewPlans.first {
            session.selectedPaperPlan = plan
            session.actualPaper = plan.sheetSize
            session.guidanceMode = .tabletop
            session.currentStep = 4
            session.stage = .guidance
        } else {
            session.stage = .paperPlans
        }
        return true
    }
    #endif
}
