import XCTest
@testable import WrapGuide

@MainActor
final class PlannerCoordinatorTests: XCTestCase {
    func testStartsOnInputAndCalculatesEasyWrap() throws {
        let coordinator = PlannerCoordinator()

        XCTAssertEqual(coordinator.route, .input)
        XCTAssertTrue(coordinator.plans.isEmpty)

        coordinator.calculate()

        XCTAssertEqual(coordinator.route, .results)
        XCTAssertEqual(coordinator.selectedStrategy, .easyWrap)
        XCTAssertEqual(try XCTUnwrap(coordinator.selectedPlan).cutSize, PaperSpec(widthMM: 430, heightMM: 370))
    }

    func testStrategySelectionAndEditPreserveDimensions() throws {
        let coordinator = PlannerCoordinator()
        coordinator.dimensions = BoxDimensions(lengthMM: 300, widthMM: 200, heightMM: 80)
        coordinator.calculate()
        coordinator.select(.justFit)

        XCTAssertEqual(try XCTUnwrap(coordinator.selectedPlan).strategy, .justFit)

        coordinator.editDimensions()

        XCTAssertEqual(coordinator.route, .input)
        XCTAssertEqual(coordinator.dimensions, BoxDimensions(lengthMM: 300, widthMM: 200, heightMM: 80))
    }

    func testResetReturnsToKnownDefault() {
        let coordinator = PlannerCoordinator()
        coordinator.calculate()
        coordinator.select(.justFit)

        coordinator.reset()

        XCTAssertEqual(coordinator.route, .input)
        XCTAssertEqual(coordinator.dimensions, .phoneBox)
        XCTAssertEqual(coordinator.selectedStrategy, .easyWrap)
        XCTAssertTrue(coordinator.plans.isEmpty)
    }

    func testCustomPaperEvaluationUsesCurrentDimensions() {
        let coordinator = PlannerCoordinator()
        coordinator.calculate()

        let result = coordinator.evaluateCustomPaper(PaperSpec(widthMM: 370, heightMM: 430))

        XCTAssertTrue(result.isFeasible)
        XCTAssertEqual(result.rotationDegrees, 90)
    }
}
