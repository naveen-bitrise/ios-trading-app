import Foundation
import Combine

/// Holds cash and positions, and is the single place an order gets applied.
final class PortfolioStore: ObservableObject {
    static let defaultStartingCash: Double = 25_000

    @Published private(set) var cash: Double
    @Published private(set) var positions: [String: Position]
    @Published private(set) var filledOrders: [Order] = []

    init(cash: Double = PortfolioStore.defaultStartingCash, positions: [String: Position] = [:]) {
        self.cash = cash
        self.positions = positions
    }

    func position(for symbol: String) -> Position {
        positions[symbol] ?? Position(symbol: symbol)
    }

    func heldQuantity(for symbol: String) -> Int {
        position(for: symbol).quantity
    }

    var sortedPositions: [Position] {
        positions.values.filter { $0.quantity > 0 }.sorted { $0.symbol < $1.symbol }
    }

    /// Validates an order against the current balances without mutating anything.
    func validate(_ order: Order) -> OrderError? {
        guard order.quantity > 0 else { return .invalidQuantity }

        if order.type == .limit {
            guard let limitPrice = order.limitPrice else { return .missingLimitPrice }
            guard limitPrice > 0 else { return .invalidLimitPrice }
        }

        switch order.side {
        case .buy:
            guard order.notional <= cash else {
                return .insufficientFunds(required: order.notional, available: cash)
            }
        case .sell:
            let held = heldQuantity(for: order.symbol)
            guard order.quantity <= held else {
                return .insufficientShares(required: order.quantity, available: held)
            }
        }

        return nil
    }

    @discardableResult
    func submit(_ order: Order) -> Result<Order, OrderError> {
        if let error = validate(order) {
            return .failure(error)
        }

        var position = position(for: order.symbol)
        switch order.side {
        case .buy:
            cash -= order.notional
            position.add(quantity: order.quantity, at: order.executionPrice)
        case .sell:
            cash += order.notional
            position.remove(quantity: order.quantity)
        }
        positions[order.symbol] = position
        filledOrders.append(order)
        return .success(order)
    }

    func reset(cash newCash: Double = PortfolioStore.defaultStartingCash) {
        cash = newCash
        positions = [:]
        filledOrders = []
    }
}
