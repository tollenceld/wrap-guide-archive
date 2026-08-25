import XCTest
@testable import WrapGuide

final class PaperPlannerTests: XCTestCase {
    private let planner = PaperPlanner()
    private let box = BoxDimensions.phoneBox

    func testEasyWrapRecommendationUsesExpectedMarginsAndRounding() throws {
        let plan = try XCTUnwrap(planner.recommend(for: box).first { $0.strategy == .easyWrap })
        XCTAssertEqual(plan.cutSize.widthMM, 430)
        XCTAssertEqual(plan.cutSize.heightMM, 370)
        XCTAssertEqual(plan.margins.seamOverlapMM, 30)
        XCTAssertEqual(plan.margins.endAllowanceMM, 15)
        XCTAssertEqual(plan.orientation, .longAxis)
    }

    func testJustFitRecommendationUsesExpectedMarginsAndRounding() throws {
        let plan = try XCTUnwrap(planner.recommend(for: box).first { $0.strategy == .justFit })
        XCTAssertEqual(plan.cutSize.widthMM, 415)
        XCTAssertEqual(plan.cutSize.heightMM, 350)
        XCTAssertEqual(plan.margins.seamOverlapMM, 15)
        XCTAssertEqual(plan.margins.endAllowanceMM, 5)
    }

    func testCustomPaperCanUseRotatedSheet() {
        let plan = planner.evaluate(custom: PaperSpec(widthMM: 370, heightMM: 430), for: box)
        XCTAssertTrue(plan.isFeasible)
        XCTAssertEqual(plan.difficulty, .comfortable)
        XCTAssertEqual(plan.rotationDegrees, 90)
    }

    func testCustomPaperFallsBackToPreciseMargins() {
        let plan = planner.evaluate(custom: PaperSpec(widthMM: 415, heightMM: 350), for: box)
        XCTAssertTrue(plan.isFeasible)
        XCTAssertEqual(plan.difficulty, .precise)
        XCTAssertEqual(plan.margins, PaperPlanner.justFitMargins)
    }

    func testInsufficientPaperIsRejected() {
        let plan = planner.evaluate(custom: PaperSpec(widthMM: 250, heightMM: 250), for: box)
        XCTAssertFalse(plan.isFeasible)
        XCTAssertEqual(plan.difficulty, .insufficient)
    }

    func testOversizedPaperRecommendsCutting() {
        let plan = planner.evaluate(custom: PaperSpec(widthMM: 700, heightMM: 500), for: box)
        XCTAssertTrue(plan.recommendsCutting)
        XCTAssertGreaterThan(plan.wasteRatio, 0.4)
    }

    func testInvalidBoxHasNoRecommendations() {
        let invalid = BoxDimensions(lengthMM: 0, widthMM: 100, heightMM: 20)
        XCTAssertTrue(planner.recommend(for: invalid).isEmpty)
    }
}

