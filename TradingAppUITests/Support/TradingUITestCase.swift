import XCTest

/// Shared launch/query/attachment helpers for the UI test suites.
class TradingUITestCase: XCTestCase {
    var app: XCUIApplication!

    /// Cash the app starts with. Override per test to exercise error paths.
    var startingCash: Double { 25_000 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITests"]
        app.launchEnvironment["UITEST_STARTING_CASH"] = String(startingCash)
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Queries

    /// Accessibility identifiers can land on a cell, a button or a static text
    /// depending on how SwiftUI renders the container, so query by identifier
    /// across all element types.
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @discardableResult
    func waitForElement(_ identifier: String, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let target = element(identifier)
        XCTAssertTrue(
            target.waitForExistence(timeout: timeout),
            "Timed out waiting for element “\(identifier)”",
            file: file,
            line: line
        )
        return target
    }

    // MARK: - Flow helpers

    func openTicket(for symbol: String) {
        waitForElement("quote.\(symbol)").tap()
        _ = waitForElement("ticket.placeOrder")
    }

    func goBackToWatchlist() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        _ = waitForElement("watchlist.cash")
    }

    func tapIncrement(times: Int) {
        let increment = element("ticket.quantity.increment")
        for _ in 0..<times {
            increment.tap()
        }
    }

    /// Empties a text field. Tapping the trailing edge puts the caret after the
    /// last character — tapping the centre of a right-aligned field lands in the
    /// empty space before the text, where delete keys do nothing.
    func clearText(in field: XCUIElement) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let existing = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count + 2))
    }

    // MARK: - Attachments

    /// Captures the current screen and attaches it to the test report.
    @discardableResult
    func attachScreenshot(named name: String) -> XCTAttachment {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        return attachment
    }
}
