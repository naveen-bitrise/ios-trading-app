import Foundation

/// A holding in the portfolio, tracked with an average cost basis.
struct Position: Equatable, Identifiable {
    let symbol: String
    private(set) var quantity: Int
    private(set) var averageCost: Double

    var id: String { symbol }

    init(symbol: String, quantity: Int = 0, averageCost: Double = 0) {
        self.symbol = symbol
        self.quantity = quantity
        self.averageCost = averageCost
    }

    var costBasis: Double {
        Double(quantity) * averageCost
    }

    func marketValue(at price: Double) -> Double {
        Double(quantity) * price
    }

    func unrealizedPnL(at price: Double) -> Double {
        marketValue(at: price) - costBasis
    }

    mutating func add(quantity addedQuantity: Int, at price: Double) {
        let newQuantity = quantity + addedQuantity
        guard newQuantity > 0 else {
            quantity = 0
            averageCost = 0
            return
        }
        let newCost = costBasis + Double(addedQuantity) * price
        averageCost = newCost / Double(newQuantity)
        quantity = newQuantity
    }

    mutating func remove(quantity removedQuantity: Int) {
        quantity = max(0, quantity - removedQuantity)
        if quantity == 0 {
            averageCost = 0
        }
    }
}
