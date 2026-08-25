import XCTest

final class WrapGuideUITests: XCTestCase {
    @MainActor
    func testPlannerActionsRemainHittableWithoutScrolling() throws {
        let app = launch(language: "en", locale: "en_US")

        let calculate = app.buttons["plannerCalculateButton"]
        XCTAssertTrue(calculate.waitForExistence(timeout: 5))
        XCTAssertTrue(calculate.isHittable)
        calculate.tap()

        let justFit = app.buttons["paperPlan_justFit"]
        let custom = app.buttons["customPaperButton"]
        XCTAssertTrue(justFit.waitForExistence(timeout: 3))
        XCTAssertTrue(justFit.isHittable)
        justFit.tap()
        XCTAssertTrue(custom.isHittable)
        custom.tap()

        let close = app.buttons["customPaperCloseButton"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["customPaperFitStatus"].exists)
        XCTAssertTrue(close.isHittable)
        close.tap()

        XCTAssertTrue(custom.waitForExistence(timeout: 3))
        XCTAssertTrue(custom.isHittable)
    }

    @MainActor
    func testChinesePlannerFlowAndRotationResult() throws {
        let app = launch(language: "zh-Hans", locale: "zh_CN")

        let calculate = app.buttons["plannerCalculateButton"]
        XCTAssertTrue(calculate.waitForExistence(timeout: 5))
        XCTAssertTrue(calculate.isHittable)
        calculate.tap()

        let custom = app.buttons["customPaperButton"]
        XCTAssertTrue(custom.waitForExistence(timeout: 3))
        XCTAssertTrue(custom.isHittable)
        custom.tap()

        XCTAssertTrue(app.staticTexts["customPaperFitStatus"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["90°"].exists)
        XCTAssertTrue(app.buttons["customPaperCloseButton"].isHittable)
    }

    @MainActor
    func testLargestAccessibilityTextKeepsPrimaryActionVisible() throws {
        let app = launch(
            language: "en",
            locale: "en_US",
            extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        )

        let calculate = app.buttons["plannerCalculateButton"]
        XCTAssertTrue(calculate.waitForExistence(timeout: 5))
        XCTAssertTrue(calculate.isHittable)
        calculate.tap()

        let custom = app.buttons["customPaperButton"]
        XCTAssertTrue(custom.waitForExistence(timeout: 3))
        XCTAssertTrue(custom.isHittable)
    }

    @MainActor
    private func launch(language: String, locale: String, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale
        ] + extraArguments
        app.launch()
        return app
    }
}
