import XCTest
@testable import TradingApp

final class QuoteTests: XCTestCase {
    func testChangeAndPercentForRisingQuote() {
        let quote = Quote(symbol: "AAPL", name: "Apple Inc.", price: 110, previousClose: 100)
        XCTAssertEqual(quote.change, 10, accuracy: 0.0001)
        XCTAssertEqual(quote.changePercent, 10, accuracy: 0.0001)
        XCTAssertTrue(quote.isUp)
    }

    func testChangeAndPercentForFallingQuote() {
        let quote = Quote(symbol: "TSLA", name: "Tesla Inc.", price: 90, previousClose: 100)
        XCTAssertEqual(quote.change, -10, accuracy: 0.0001)
        XCTAssertEqual(quote.changePercent, -10, accuracy: 0.0001)
        XCTAssertFalse(quote.isUp)
    }

    func testChangePercentIsZeroWhenPreviousCloseIsZero() {
        let quote = Quote(symbol: "NEW", name: "Newly Listed", price: 25, previousClose: 0)
        XCTAssertEqual(quote.changePercent, 0)
    }

    func testQuoteIsIdentifiedBySymbol() {
        let quote = Quote(symbol: "MSFT", name: "Microsoft Corp.", price: 1, previousClose: 1)
        XCTAssertEqual(quote.id, "MSFT")
    }

    func testStubServiceReturnsDistinctSymbols() {
        let quotes = StubMarketDataService().loadQuotes()
        XCTAssertFalse(quotes.isEmpty)
        XCTAssertEqual(Set(quotes.map(\.symbol)).count, quotes.count)
    }
}
