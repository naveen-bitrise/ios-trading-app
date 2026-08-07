import Foundation

protocol MarketDataProviding {
    func loadQuotes() -> [Quote]
}

/// Deterministic, offline market data. Real network access would make the
/// UI tests flaky and the build unable to run in a sandboxed CI machine.
struct StubMarketDataService: MarketDataProviding {
    static let sampleQuotes: [Quote] = [
        Quote(symbol: "AAPL", name: "Apple Inc.", price: 224.50, previousClose: 220.10),
        Quote(symbol: "MSFT", name: "Microsoft Corp.", price: 418.20, previousClose: 421.75),
        Quote(symbol: "NVDA", name: "NVIDIA Corp.", price: 132.85, previousClose: 126.40),
        Quote(symbol: "TSLA", name: "Tesla Inc.", price: 245.10, previousClose: 251.30),
        Quote(symbol: "AMZN", name: "Amazon.com Inc.", price: 186.75, previousClose: 184.20),
        Quote(symbol: "GOOG", name: "Alphabet Inc.", price: 172.40, previousClose: 173.95),
        Quote(symbol: "META", name: "Meta Platforms Inc.", price: 512.60, previousClose: 498.10),
        Quote(symbol: "NFLX", name: "Netflix Inc.", price: 642.30, previousClose: 655.00)
    ]

    func loadQuotes() -> [Quote] {
        Self.sampleQuotes
    }
}
