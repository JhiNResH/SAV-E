import XCTest

final class SAVEOnboardingCarouselTests: XCTestCase {
    func testCarouselReachesFirstPlaceInput() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-save.appLanguage", "en"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Stop losing places friends send you."].waitForExistence(timeout: 10))

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Memo finds the real place."].waitForExistence(timeout: 3))

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Save only what you confirm."].waitForExistence(timeout: 3))

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Rescue one place now"].waitForExistence(timeout: 3))

        let saveButton = app.buttons["Save my first place"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)

        app.buttons["Try sample clue"].tap()
        XCTAssertTrue(saveButton.isEnabled)
    }
}
