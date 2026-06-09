import XCTest

final class SAVEOnboardingCarouselTests: XCTestCase {
    func testCarouselReachesFirstPlaceInput() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-save.appLanguage", "en"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Keep the clue before it disappears."].waitForExistence(timeout: 10))

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["SAV-E shows why it guessed."].waitForExistence(timeout: 3))

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Confirm before it becomes memory."].waitForExistence(timeout: 3))

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Rescue one place now"].waitForExistence(timeout: 3))

        let saveButton = app.buttons["Save my first place"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)

        app.buttons["Try sample clue"].tap()
        XCTAssertTrue(saveButton.isEnabled)
    }
}
