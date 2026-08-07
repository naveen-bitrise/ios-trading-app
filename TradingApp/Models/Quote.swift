import Foundation

/// A tradable instrument with its latest price.
struct Quote: Identifiable, Equatable, Hashable {
    let symbol: String
    let name: String
    let price: Double
    let previousClose: Double

    var id: String { symbol }

    var change: Double {
        price - previousClose
    }

    var changePercent: Double {
        guard previousClose != 0 else { return 0 }
        return (change / previousClose) * 100
    }

    var isUp: Bool {
        change >= 0
    }
}
