import XCTest

final class WrapGuideUITests: XCTestCase {
    @MainActor
    func testManualFlowReachesGuidanceAndCompletion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["startWrapButton"].waitForExistence(timeout: 5))
        app.buttons["Enter dimensions manually"].tap()

        let manualContinue = app.buttons["manualContinueButton"]
        XCTAssertTrue(manualContinue.waitForExistence(timeout: 3))
        scrollToAndTap(manualContinue, in: app)

        let confirm = app.buttons["confirmDimensionsButton"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        scrollToAndTap(confirm, in: app)

        let easyWrap = app.buttons["paperPlan_easyWrap"]
        XCTAssertTrue(easyWrap.waitForExistence(timeout: 3))
        scrollToAndTap(easyWrap, in: app)

        let begin = app.buttons["beginGuidanceButton"]
        XCTAssertTrue(begin.waitForExistence(timeout: 3))
        scrollToAndTap(begin, in: app)

        let done = app.buttons["guidanceDoneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        for _ in 0..<12 {
            XCTAssertTrue(done.waitForExistence(timeout: 2))
            done.tap()
        }

        XCTAssertTrue(app.buttons["wrapAnotherButton"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSimulatedScanProducesEditableDimensions() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["startWrapButton"].tap()
        XCTAssertTrue(app.buttons["confirmDimensionsButton"].waitForExistence(timeout: 6))
    }

    @MainActor
    private func scrollToAndTap(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while !element.isHittable && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        element.tap()
    }
}
