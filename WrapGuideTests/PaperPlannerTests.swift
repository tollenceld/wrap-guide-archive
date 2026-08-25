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
        XCTAssertEqual(plan.cutSize, PaperSpec(widthMM: 415, heightMM: 350))
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

    func testInvalidPaperIsRejectedWithRealMinimum() {
        let plan = planner.evaluate(custom: PaperSpec(widthMM: 0, heightMM: 0), for: box)

        XCTAssertEqual(plan.difficulty, .insufficient)
        XCTAssertEqual(plan.cutSize, PaperSpec(widthMM: 415, heightMM: 350))
    }

    func testAreaAloneDoesNotClaimThatPaperFits() {
        let narrowSheet = PaperSpec(widthMM: 200, heightMM: 800)
        XCTAssertGreaterThan(narrowSheet.area, PaperSpec(widthMM: 415, heightMM: 350).area)

        let plan = planner.evaluate(custom: narrowSheet, for: box)

        XCTAssertFalse(plan.isFeasible)
        XCTAssertEqual(plan.difficulty, .insufficient)
    }

    func testRecommendationSortsHorizontalBoxAxes() throws {
        let reversed = BoxDimensions(lengthMM: 138, widthMM: 214, heightMM: 62)
        let plan = try XCTUnwrap(planner.recommend(for: reversed).first)

        XCTAssertEqual(plan.cutSize, PaperSpec(widthMM: 430, heightMM: 370))
        XCTAssertEqual(plan.orientation, .longAxis)
    }

    func testMetricAndImperialFormattingUseMillimetresInternally() {
        XCTAssertEqual(box.formatted(unit: .metric), "21.4 × 13.8 × 6.2 cm")
        XCTAssertEqual(PaperSpec(widthMM: 254, heightMM: 508).formatted(unit: .imperial), "10.0 × 20.0 in")
    }
}
