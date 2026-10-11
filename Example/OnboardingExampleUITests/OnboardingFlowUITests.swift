import XCTest

/// Walks the example flow end to end on a real SwiftUI host. Regression test
/// for the iOS 26 crash (0.1.0): a question shown right after a static
/// screen was rendered on SwiftUI's async renderer and trapped on a main
/// actor check. If the app crashes, the next query fails the test.
final class OnboardingFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    private var primary: XCUIElement { app.buttons["onboarding.primary"] }

    private func option(_ id: String) -> XCUIElement {
        app.buttons["onboarding.option.\(id)"]
    }

    private func waitFor(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(element)", file: file, line: line)
    }

    /// Lets the transition settle with nothing moving on screen, which is
    /// what sent the next render to the async renderer.
    private func idle() {
        Thread.sleep(forTimeInterval: 1.2)
    }

    func testFullFlowCompletesWithoutCrashing() {
        // Hero (static) -> question.
        waitFor(app.staticTexts["Sleep better tonight"])
        idle()
        primary.tap()

        waitFor(app.staticTexts["What brings you here?"])
        XCTAssertTrue(option("fall_asleep").label.contains("Drift off faster"), "Option subtitle is rendered")
        XCTAssertFalse(primary.isEnabled)
        idle()
        option("focus").tap()
        idle()
        XCTAssertTrue(primary.isEnabled)

        // Back to the static hero and forward again (reverse transition).
        app.buttons["Back"].tap()
        waitFor(app.staticTexts["Sleep better tonight"])
        idle()
        primary.tap()
        waitFor(app.staticTexts["What brings you here?"])
        idle()
        primary.tap()

        // Multi choice.
        waitFor(app.staticTexts["When do you listen?"])
        idle()
        option("night").tap()
        option("work").tap()
        idle()
        primary.tap()

        // Benefits -> static hero -> auto-advancing question.
        waitFor(app.staticTexts["Everything you need"])
        idle()
        primary.tap()
        waitFor(app.staticTexts["Almost there"])
        idle()
        primary.tap()
        waitFor(app.staticTexts["How loud do you like it?"])
        idle()
        tapUntilGone(option("loud"))

        // Loading advances by itself and finishes the flow.
        waitFor(app.staticTexts["Setting up your sound"])
        XCTAssertTrue(app.staticTexts["example.finished"].waitForExistence(timeout: 10))
        let answers = app.staticTexts["example.answers"].label
        XCTAssertTrue(answers.contains("goal=focus"), answers)
        XCTAssertTrue(answers.contains("when=night,work"), answers)
        XCTAssertTrue(answers.contains("volume=loud"), answers)
    }

    /// Taps an auto-advancing option; retries once if the first tap was
    /// swallowed while the step was still settling (seen on a cold simulator).
    private func tapUntilGone(_ element: XCUIElement) {
        element.tap()
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: element)
        if XCTWaiter().wait(for: [expectation], timeout: 3) != .completed {
            element.tap()
        }
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Every step in landscape, for visual review (attachments in the .xcresult).
    func testLandscapeEveryStepReachesContinue() {
        waitFor(app.staticTexts["Sleep better tonight"])
        XCUIDevice.shared.orientation = .landscapeLeft
        idle()
        let steps: [(String, () -> Void)] = [
            ("welcome", {}),
            ("goal", { self.option("baby").tap() }),
            ("when", { self.option("nap").tap() }),
            ("benefits", {}),
            ("almost", {})
        ]
        for (name, answer) in steps {
            idle()
            snapshot("landscape-\(name)")
            answer()
            var swipes = 0
            while !primary.isHittable && swipes < 6 {
                app.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(primary.isHittable, "Continue reachable on \(name)")
            primary.tap()
        }
        waitFor(app.staticTexts["How loud do you like it?"])
        idle()
        snapshot("landscape-volume")
        tapUntilGone(option("soft"))
        waitFor(app.staticTexts["Setting up your sound"])
        snapshot("landscape-loading")
        XCTAssertTrue(app.staticTexts["example.finished"].waitForExistence(timeout: 10))
    }

    /// In landscape the question doesn't fit: it must scroll instead of being
    /// cut, and every option must stay reachable.
    func testLandscapeScrollsInsteadOfCutting() {
        waitFor(app.staticTexts["Sleep better tonight"])
        XCUIDevice.shared.orientation = .landscapeLeft
        idle()
        XCTAssertTrue(app.staticTexts["Sleep better tonight"].exists)
        XCTAssertTrue(primary.isHittable)
        primary.tap()

        waitFor(app.staticTexts["What brings you here?"])
        idle()
        let last = option("tinnitus")
        waitFor(last)
        var swipes = 0
        while !last.isHittable && swipes < 6 {
            app.scrollViews.firstMatch.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(last.isHittable, "Last option reachable by scrolling")
        last.tap()
        XCTAssertTrue(primary.isHittable)
        primary.tap()
        waitFor(app.staticTexts["When do you listen?"])
    }
}
