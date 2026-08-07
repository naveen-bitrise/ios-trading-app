import XCTest

/// Screenshot-attaching UI tests for the watchlist screen.
final class WatchlistUITests: TradingUITestCase {
    func testWatchlistShowsQuotesAndBuyingPower() {
        app.launch()

        let cash = waitForElement("watchlist.cash")
        XCTAssertEqual(cash.label, "$25,000.00")

        XCTAssertTrue(element("quote.AAPL").exists)
        XCTAssertTrue(element("quote.TSLA").exists)
        XCTAssertTrue(app.staticTexts["Markets"].exists)

        attachScreenshot(named: "01-watchlist")
    }

    func testSearchFiltersTheWatchlist() {
        app.launch()

        let search = waitForElement("watchlist.search")
        search.tap()
        search.typeText("TSLA")

        XCTAssertTrue(element("quote.TSLA").waitForExistence(timeout: 5))
        XCTAssertFalse(element("quote.AAPL").exists)
        attachScreenshot(named: "02-search-matching-symbol")

        element("watchlist.clearSearch").tap()
        XCTAssertTrue(element("quote.AAPL").waitForExistence(timeout: 5))
        attachScreenshot(named: "03-search-cleared")
    }

    func testSearchWithNoMatchesShowsEmptyState() {
        app.launch()

        let search = waitForElement("watchlist.search")
        search.tap()
        search.typeText("ZZZZ")

        XCTAssertTrue(element("watchlist.emptyState").waitForExistence(timeout: 5))
        attachScreenshot(named: "04-search-empty-state")
    }

    func testSortToggleReordersTheWatchlist() {
        app.launch()

        let sortToggle = waitForElement("watchlist.sortToggle")
        XCTAssertEqual(sortToggle.label, "Symbol")
        attachScreenshot(named: "05-sorted-by-symbol")

        sortToggle.tap()
        XCTAssertTrue(element("watchlist.sortToggle").waitForExistence(timeout: 5))
        XCTAssertEqual(element("watchlist.sortToggle").label, "Top Movers")
        attachScreenshot(named: "06-sorted-by-top-movers")
    }
}
