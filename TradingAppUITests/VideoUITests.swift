import XCTest

/// The two tests below record the flow they drive and attach the resulting
/// `.mp4` to the test report. Bitrise collates video attachments from the
/// xcresult onto the test result page alongside the pass/fail status.
final class VideoUITests: TradingUITestCase {
    private var recorder: ScreenRecorder!

    override func setUpWithError() throws {
        try super.setUpWithError()
        recorder = ScreenRecorder(framesPerSecond: 8, targetWidth: 360)
    }

    override func tearDownWithError() throws {
        // Guarantees the capture loop is stopped even if a test fails midway.
        _ = recorder?.stop()
        recorder = nil
        try super.tearDownWithError()
    }

    func testBuyOrderFlowRecordsVideo() {
        app.launch()
        _ = waitForElement("watchlist.cash")

        recorder.start()

        openTicket(for: "NVDA")
        tapIncrement(times: 4)
        XCTAssertEqual(element("ticket.quantity").label, "5")
        element("ticket.placeOrder").tap()

        let status = waitForElement("ticket.status")
        XCTAssertEqual(status.label, "Buy 5 NVDA filled at $132.85")

        goBackToWatchlist()
        XCTAssertTrue(element("position.NVDA").exists)
        XCTAssertEqual(element("watchlist.cash").label, "$24,335.75")

        recorder.captureFrame()
        recorder.attachVideo(to: self, name: "buy-order-flow.mp4")
        attachScreenshot(named: "buy-order-flow-final-frame")
    }

    func testSearchAndSellFlowRecordsVideo() {
        app.launch()
        _ = waitForElement("watchlist.cash")

        recorder.start()

        // Buy first so there is a position to sell.
        openTicket(for: "META")
        tapIncrement(times: 2)
        element("ticket.placeOrder").tap()
        XCTAssertEqual(waitForElement("ticket.status").label, "Buy 3 META filled at $512.60")
        goBackToWatchlist()

        // Find the symbol again through search, then close half the position.
        let search = waitForElement("watchlist.search")
        search.tap()
        search.typeText("META")
        waitForElement("quote.META").tap()
        _ = waitForElement("ticket.placeOrder")

        element("ticket.side.sell").tap()
        tapIncrement(times: 1)
        element("ticket.placeOrder").tap()

        let status = waitForElement("ticket.status")
        XCTAssertEqual(status.label, "Sell 2 META filled at $512.60")
        XCTAssertEqual(element("ticket.held").label, "1")

        recorder.captureFrame()
        recorder.attachVideo(to: self, name: "search-and-sell-flow.mp4")
        attachScreenshot(named: "search-and-sell-flow-final-frame")
    }
}
