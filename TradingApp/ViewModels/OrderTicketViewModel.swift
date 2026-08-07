import Foundation
import Combine

final class OrderTicketViewModel: ObservableObject {
    let quote: Quote

    @Published var side: OrderSide = .buy
    @Published var orderType: OrderType = .market
    @Published var quantity: Int = 1
    @Published var limitPriceText: String = ""
    @Published private(set) var statusMessage: String?
    @Published private(set) var isError: Bool = false

    private let portfolio: PortfolioStore

    init(quote: Quote, portfolio: PortfolioStore) {
        self.quote = quote
        self.portfolio = portfolio
        self.limitPriceText = String(format: "%.2f", quote.price)
    }

    var limitPrice: Double? {
        Double(limitPriceText.trimmingCharacters(in: .whitespaces))
    }

    /// The price the ticket will execute at: the limit for limit orders, the
    /// last traded price for market orders.
    var executionPrice: Double {
        orderType == .limit ? (limitPrice ?? 0) : quote.price
    }

    var estimatedCost: Double {
        Double(quantity) * executionPrice
    }

    var heldQuantity: Int {
        portfolio.heldQuantity(for: quote.symbol)
    }

    var availableCash: Double {
        portfolio.cash
    }

    var currentOrder: Order {
        Order(
            symbol: quote.symbol,
            side: side,
            type: orderType,
            quantity: quantity,
            limitPrice: orderType == .limit ? limitPrice : nil,
            executionPrice: executionPrice
        )
    }

    func increment() {
        quantity += 1
    }

    func decrement() {
        quantity = max(0, quantity - 1)
    }

    func setSide(_ newSide: OrderSide) {
        side = newSide
        clearStatus()
    }

    func setOrderType(_ newType: OrderType) {
        orderType = newType
        clearStatus()
    }

    func clearStatus() {
        statusMessage = nil
        isError = false
    }

    @discardableResult
    func placeOrder() -> Result<Order, OrderError> {
        let order = currentOrder
        let result = portfolio.submit(order)
        switch result {
        case let .success(filled):
            isError = false
            statusMessage = "\(filled.side.rawValue) \(filled.quantity) \(filled.symbol) filled at \(PriceFormatter.currency(filled.executionPrice))"
        case let .failure(error):
            isError = true
            statusMessage = error.message
        }
        return result
    }
}
