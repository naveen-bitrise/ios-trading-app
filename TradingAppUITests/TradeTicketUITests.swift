import XCTest

/// Screenshot-attaching UI tests for the order ticket screen.
final class TradeTicketUITests: TradingUITestCase {
    func testBuyOrderFillsAndUpdatesThePortfolio() {
        app.launch()
        openTicket(for: "AAPL")

        XCTAssertEqual(element("ticket.price").label, "$224.50")
        XCTAssertEqual(element("ticket.estimatedCost").label, "$224.50")
        attachScreenshot(named: "10-ticket-opened")

        tapIncrement(times: 2)
        XCTAssertEqual(element("ticket.quantity").label, "3")
        XCTAssertEqual(element("ticket.estimatedCost").label, "$673.50")
        attachScreenshot(named: "11-quantity-increased")

        element("ticket.placeOrder").tap()

        let status = waitForElement("ticket.status")
        XCTAssertEqual(status.label, "Buy 3 AAPL filled at $224.50")
        XCTAssertEqual(element("ticket.held").label, "3")
        attachScreenshot(named: "12-order-filled")

        goBackToWatchlist()
        XCTAssertEqual(element("watchlist.cash").label, "$24,326.50")
        XCTAssertTrue(element("position.AAPL").exists)
        attachScreenshot(named: "13-portfolio-after-buy")
    }

    func testSellOrderReducesThePosition() {
        app.launch()
        openTicket(for: "MSFT")

        tapIncrement(times: 3)
        element("ticket.placeOrder").tap()
        XCTAssertTrue(element("ticket.status").waitForExistence(timeout: 5))

        element("ticket.side.sell").tap()
        XCTAssertFalse(element("ticket.status").exists)
        element("ticket.quantity.decrement").tap()
        XCTAssertEqual(element("ticket.quantity").label, "3")
        attachScreenshot(named: "20-sell-ticket")

        element("ticket.placeOrder").tap()
        let status = waitForElement("ticket.status")
        XCTAssertEqual(status.label, "Sell 3 MSFT filled at $418.20")
        XCTAssertEqual(element("ticket.held").label, "1")
        attachScreenshot(named: "21-sell-filled")
    }

    func testLimitOrderRecalculatesTheEstimatedCost() {
        app.launch()
        openTicket(for: "NVDA")

        element("ticket.orderType.limit").tap()
        let limitField = waitForElement("ticket.limitPrice")
        XCTAssertEqual(limitField.value as? String, "132.85")
        attachScreenshot(named: "30-limit-order-selected")

        clearText(in: limitField)
        XCTAssertEqual(element("ticket.estimatedCost").label, "$0.00")
        limitField.typeText("100")

        XCTAssertEqual(element("ticket.estimatedCost").label, "$100.00")
        attachScreenshot(named: "31-limit-price-edited")

        element("ticket.placeOrder").tap()
        let status = waitForElement("ticket.status")
        XCTAssertEqual(status.label, "Buy 1 NVDA filled at $100.00")
        attachScreenshot(named: "32-limit-order-filled")
    }
}

/// The insufficient-funds path needs a much smaller starting balance.
final class TradeTicketValidationUITests: TradingUITestCase {
    override var startingCash: Double { 300 }

    func testOrderLargerThanBuyingPowerIsRejected() {
        app.launch()
        XCTAssertEqual(waitForElement("watchlist.cash").label, "$300.00")

        openTicket(for: "AAPL")
        tapIncrement(times: 1)
        XCTAssertEqual(element("ticket.estimatedCost").label, "$449.00")
        attachScreenshot(named: "40-unaffordable-ticket")

        element("ticket.placeOrder").tap()

        let status = waitForElement("ticket.status")
        XCTAssertEqual(status.label, "Insufficient funds: $449.00 needed, $300.00 available.")
        XCTAssertEqual(element("ticket.held").label, "0")
        attachScreenshot(named: "41-insufficient-funds-error")

        goBackToWatchlist()
        XCTAssertEqual(element("watchlist.cash").label, "$300.00")
    }
}
