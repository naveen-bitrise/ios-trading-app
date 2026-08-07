import XCTest
@testable import TradingApp

final class PortfolioStoreTests: XCTestCase {
    private func marketBuy(_ symbol: String = "AAPL", quantity: Int, at price: Double) -> Order {
        Order(symbol: symbol, side: .buy, type: .market, quantity: quantity, limitPrice: nil, executionPrice: price)
    }

    private func marketSell(_ symbol: String = "AAPL", quantity: Int, at price: Double) -> Order {
        Order(symbol: symbol, side: .sell, type: .market, quantity: quantity, limitPrice: nil, executionPrice: price)
    }

    func testBuyDebitsCashAndOpensPosition() {
        let store = PortfolioStore(cash: 1_000)
        let result = store.submit(marketBuy(quantity: 4, at: 100))

        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(store.cash, 600, accuracy: 0.0001)
        XCTAssertEqual(store.heldQuantity(for: "AAPL"), 4)
        XCTAssertEqual(store.position(for: "AAPL").averageCost, 100, accuracy: 0.0001)
        XCTAssertEqual(store.filledOrders.count, 1)
    }

    func testSellCreditsCashAndReducesPosition() {
        let store = PortfolioStore(cash: 1_000)
        store.submit(marketBuy(quantity: 5, at: 100))
        store.submit(marketSell(quantity: 2, at: 110))

        XCTAssertEqual(store.cash, 720, accuracy: 0.0001)
        XCTAssertEqual(store.heldQuantity(for: "AAPL"), 3)
        XCTAssertEqual(store.filledOrders.count, 2)
    }

    func testBuyIsRejectedWhenCashIsInsufficient() {
        let store = PortfolioStore(cash: 100)
        let result = store.submit(marketBuy(quantity: 2, at: 100))

        guard case let .failure(error) = result else {
            return XCTFail("Expected the order to be rejected")
        }
        XCTAssertEqual(error, .insufficientFunds(required: 200, available: 100))
        XCTAssertEqual(store.cash, 100, accuracy: 0.0001)
        XCTAssertEqual(store.heldQuantity(for: "AAPL"), 0)
        XCTAssertTrue(store.filledOrders.isEmpty)
    }

    func testBuyIsAllowedWhenCostExactlyMatchesCash() {
        let store = PortfolioStore(cash: 200)
        let result = store.submit(marketBuy(quantity: 2, at: 100))

        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(store.cash, 0, accuracy: 0.0001)
    }

    func testSellIsRejectedWhenSharesAreInsufficient() {
        let store = PortfolioStore(cash: 1_000)
        store.submit(marketBuy(quantity: 1, at: 100))
        let result = store.submit(marketSell(quantity: 5, at: 100))

        guard case let .failure(error) = result else {
            return XCTFail("Expected the order to be rejected")
        }
        XCTAssertEqual(error, .insufficientShares(required: 5, available: 1))
        XCTAssertEqual(store.heldQuantity(for: "AAPL"), 1)
    }

    func testZeroQuantityIsRejected() {
        let store = PortfolioStore(cash: 1_000)
        let result = store.submit(marketBuy(quantity: 0, at: 100))

        guard case let .failure(error) = result else {
            return XCTFail("Expected the order to be rejected")
        }
        XCTAssertEqual(error, .invalidQuantity)
    }

    func testLimitOrderWithoutPriceIsRejected() {
        let store = PortfolioStore(cash: 1_000)
        let order = Order(symbol: "AAPL", side: .buy, type: .limit, quantity: 1, limitPrice: nil, executionPrice: 0)
        XCTAssertEqual(store.validate(order), .missingLimitPrice)
    }

    func testLimitOrderWithNonPositivePriceIsRejected() {
        let store = PortfolioStore(cash: 1_000)
        let order = Order(symbol: "AAPL", side: .buy, type: .limit, quantity: 1, limitPrice: 0, executionPrice: 0)
        XCTAssertEqual(store.validate(order), .invalidLimitPrice)
    }

    func testLimitBuyFillsAtLimitPrice() {
        let store = PortfolioStore(cash: 1_000)
        let order = Order(symbol: "AAPL", side: .buy, type: .limit, quantity: 2, limitPrice: 90, executionPrice: 90)
        store.submit(order)

        XCTAssertEqual(store.cash, 820, accuracy: 0.0001)
        XCTAssertEqual(store.position(for: "AAPL").averageCost, 90, accuracy: 0.0001)
    }

    func testSortedPositionsExcludesClosedPositionsAndIsAlphabetical() {
        let store = PortfolioStore(cash: 10_000)
        store.submit(marketBuy("TSLA", quantity: 1, at: 100))
        store.submit(marketBuy("AAPL", quantity: 1, at: 100))
        store.submit(marketBuy("MSFT", quantity: 1, at: 100))
        store.submit(marketSell("MSFT", quantity: 1, at: 100))

        XCTAssertEqual(store.sortedPositions.map(\.symbol), ["AAPL", "TSLA"])
    }

    func testResetRestoresStartingState() {
        let store = PortfolioStore(cash: 1_000)
        store.submit(marketBuy(quantity: 1, at: 100))
        store.reset(cash: 500)

        XCTAssertEqual(store.cash, 500, accuracy: 0.0001)
        XCTAssertTrue(store.positions.isEmpty)
        XCTAssertTrue(store.filledOrders.isEmpty)
    }
}
