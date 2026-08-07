import XCTest
@testable import TradingApp

final class OrderTicketViewModelTests: XCTestCase {
    private let quote = Quote(symbol: "AAPL", name: "Apple Inc.", price: 200, previousClose: 190)

    private func makeViewModel(cash: Double = 10_000) -> (OrderTicketViewModel, PortfolioStore) {
        let portfolio = PortfolioStore(cash: cash)
        return (OrderTicketViewModel(quote: quote, portfolio: portfolio), portfolio)
    }

    func testDefaultsToMarketBuyOfOneShare() {
        let (viewModel, _) = makeViewModel()
        XCTAssertEqual(viewModel.side, .buy)
        XCTAssertEqual(viewModel.orderType, .market)
        XCTAssertEqual(viewModel.quantity, 1)
        XCTAssertEqual(viewModel.limitPriceText, "200.00")
    }

    func testMarketOrderExecutesAtLastPrice() {
        let (viewModel, _) = makeViewModel()
        viewModel.quantity = 3
        XCTAssertEqual(viewModel.executionPrice, 200, accuracy: 0.0001)
        XCTAssertEqual(viewModel.estimatedCost, 600, accuracy: 0.0001)
    }

    func testLimitOrderExecutesAtLimitPrice() {
        let (viewModel, _) = makeViewModel()
        viewModel.setOrderType(.limit)
        viewModel.limitPriceText = "180.50"
        viewModel.quantity = 2
        XCTAssertEqual(viewModel.executionPrice, 180.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.estimatedCost, 361, accuracy: 0.0001)
    }

    func testUnparseableLimitPriceYieldsZeroExecutionPrice() {
        let (viewModel, _) = makeViewModel()
        viewModel.setOrderType(.limit)
        viewModel.limitPriceText = "not a number"
        XCTAssertNil(viewModel.limitPrice)
        XCTAssertEqual(viewModel.executionPrice, 0, accuracy: 0.0001)
    }

    func testIncrementAndDecrementQuantity() {
        let (viewModel, _) = makeViewModel()
        viewModel.increment()
        viewModel.increment()
        XCTAssertEqual(viewModel.quantity, 3)
        viewModel.decrement()
        XCTAssertEqual(viewModel.quantity, 2)
    }

    func testDecrementStopsAtZero() {
        let (viewModel, _) = makeViewModel()
        viewModel.decrement()
        viewModel.decrement()
        XCTAssertEqual(viewModel.quantity, 0)
    }

    func testPlacingBuyOrderUpdatesPortfolioAndReportsFill() {
        let (viewModel, portfolio) = makeViewModel(cash: 1_000)
        viewModel.quantity = 2
        let result = viewModel.placeOrder()

        XCTAssertNoThrow(try result.get())
        XCTAssertFalse(viewModel.isError)
        XCTAssertEqual(viewModel.statusMessage, "Buy 2 AAPL filled at $200.00")
        XCTAssertEqual(portfolio.cash, 600, accuracy: 0.0001)
        XCTAssertEqual(portfolio.heldQuantity(for: "AAPL"), 2)
    }

    func testPlacingUnaffordableOrderSurfacesAnError() {
        let (viewModel, portfolio) = makeViewModel(cash: 100)
        viewModel.quantity = 2
        let result = viewModel.placeOrder()

        if case .success = result {
            XCTFail("Expected the order to be rejected")
        }
        XCTAssertTrue(viewModel.isError)
        XCTAssertEqual(viewModel.statusMessage, "Insufficient funds: $400.00 needed, $100.00 available.")
        XCTAssertEqual(portfolio.cash, 100, accuracy: 0.0001)
    }

    func testSellingMoreThanHeldSurfacesAnError() {
        let (viewModel, _) = makeViewModel()
        viewModel.setSide(.sell)
        viewModel.quantity = 5
        viewModel.placeOrder()

        XCTAssertTrue(viewModel.isError)
        XCTAssertEqual(viewModel.statusMessage, "Insufficient shares: 5 needed, 0 held.")
    }

    func testSellAfterBuyCreditsCash() {
        let (viewModel, portfolio) = makeViewModel(cash: 1_000)
        viewModel.quantity = 2
        viewModel.placeOrder()

        viewModel.setSide(.sell)
        viewModel.quantity = 1
        viewModel.placeOrder()

        XCTAssertFalse(viewModel.isError)
        XCTAssertEqual(portfolio.cash, 800, accuracy: 0.0001)
        XCTAssertEqual(portfolio.heldQuantity(for: "AAPL"), 1)
    }

    func testChangingSideClearsPreviousStatus() {
        let (viewModel, _) = makeViewModel(cash: 0)
        viewModel.placeOrder()
        XCTAssertNotNil(viewModel.statusMessage)

        viewModel.setSide(.sell)
        XCTAssertNil(viewModel.statusMessage)
        XCTAssertFalse(viewModel.isError)
    }

    func testCurrentOrderOmitsLimitPriceForMarketOrders() {
        let (viewModel, _) = makeViewModel()
        viewModel.limitPriceText = "123.45"
        XCTAssertNil(viewModel.currentOrder.limitPrice)

        viewModel.setOrderType(.limit)
        XCTAssertEqual(viewModel.currentOrder.limitPrice, 123.45)
    }

    func testHeldQuantityAndCashReflectPortfolio() {
        let (viewModel, portfolio) = makeViewModel(cash: 5_000)
        XCTAssertEqual(viewModel.heldQuantity, 0)
        XCTAssertEqual(viewModel.availableCash, 5_000, accuracy: 0.0001)

        viewModel.quantity = 3
        viewModel.placeOrder()

        XCTAssertEqual(viewModel.heldQuantity, 3)
        XCTAssertEqual(viewModel.availableCash, portfolio.cash, accuracy: 0.0001)
    }
}
