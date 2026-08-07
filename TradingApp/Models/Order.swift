import Foundation

enum OrderSide: String, CaseIterable, Identifiable {
    case buy = "Buy"
    case sell = "Sell"

    var id: String { rawValue }
}

enum OrderType: String, CaseIterable, Identifiable {
    case market = "Market"
    case limit = "Limit"

    var id: String { rawValue }
}

struct Order: Equatable {
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let quantity: Int
    /// Only set for `.limit` orders.
    let limitPrice: Double?
    /// The price the order is expected to fill at.
    let executionPrice: Double

    var notional: Double {
        Double(quantity) * executionPrice
    }
}

enum OrderError: Error, Equatable {
    case invalidQuantity
    case missingLimitPrice
    case invalidLimitPrice
    case insufficientFunds(required: Double, available: Double)
    case insufficientShares(required: Int, available: Int)

    var message: String {
        switch self {
        case .invalidQuantity:
            return "Quantity must be a whole number greater than zero."
        case .missingLimitPrice:
            return "Enter a limit price for a limit order."
        case .invalidLimitPrice:
            return "Limit price must be greater than zero."
        case let .insufficientFunds(required, available):
            return "Insufficient funds: \(PriceFormatter.currency(required)) needed, \(PriceFormatter.currency(available)) available."
        case let .insufficientShares(required, available):
            return "Insufficient shares: \(required) needed, \(available) held."
        }
    }
}
