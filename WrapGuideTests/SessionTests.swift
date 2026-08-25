import XCTest
@testable import WrapGuide

final class SessionTests: XCTestCase {
    func testSessionRoundTripsThroughJSON() throws {
        var session = WrapSession.new()
        session.stage = .guidance
        session.dimensions = .phoneBox
        session.currentStep = 7

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(WrapSession.self, from: data)

        XCTAssertEqual(decoded, session)
    }

    func testStandardMethodHasStableTwelveStepSequence() {
        let steps = StandardBoxWrapMethod().steps
        XCTAssertEqual(steps.count, 12)
        XCTAssertEqual(steps.map(\.id), Array(1...12))
        XCTAssertTrue(steps[0].requiresRelock)
        XCTAssertTrue(steps[4].requiresRelock)
        XCTAssertTrue(steps[7].requiresRelock)
    }

    func testStandardMethodMapsStepsIntoSixContinuousPhases() {
        let steps = StandardBoxWrapMethod().steps
        XCTAssertEqual(Set(steps.map(\.phase)), Set(WrapPhase.allCases))
        XCTAssertEqual(steps.filter { $0.phase == .placement }.map(\.id), [1])
        XCTAssertEqual(steps.filter { $0.phase == .bodyWrap }.map(\.id), [2, 3])
        XCTAssertEqual(steps.filter { $0.phase == .mainSeam }.map(\.id), [4])
        XCTAssertEqual(steps.filter { $0.phase == .firstEnd }.map(\.id), [5, 6, 7])
        XCTAssertEqual(steps.filter { $0.phase == .secondEnd }.map(\.id), [8, 9, 10, 11])
        XCTAssertEqual(steps.filter { $0.phase == .finish }.map(\.id), [12])
    }

    func testEveryGuidanceStepHasAnActionAndVisibleTarget() {
        for step in StandardBoxWrapMethod().steps {
            XCTAssertTrue(step.hasActiveAction, "Step \(step.id) has no active action")
            XCTAssertTrue(step.hasTarget, "Step \(step.id) has no visible target")
            XCTAssertGreaterThan(step.targetHoldSeconds, 0)
        }
    }

    func testGuidanceGeometryRoundTripsThroughJSON() throws {
        let step = try XCTUnwrap(StandardBoxWrapMethod().steps.first { $0.id == 6 })
        let data = try JSONEncoder().encode(step)
        XCTAssertEqual(try JSONDecoder().decode(GuidanceStep.self, from: data), step)
    }

    func testScanVisualizationStartsWithoutInventedDimensions() {
        let state = ScanVisualizationState.searching
        XCTAssertEqual(state.phase, .findingSurface)
        XCTAssertTrue(state.candidate.isEmpty)
        XCTAssertNil(state.dimensions)
        XCTAssertEqual(state.edgeProgress, 0)
    }
}
