import Foundation
import Combine

enum WatchlistSort: String, CaseIterable {
    case symbol = "Symbol"
    case topMovers = "Top Movers"
}

final class WatchlistViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var sort: WatchlistSort = .symbol
    @Published private(set) var quotes: [Quote]

    private let service: MarketDataProviding

    init(service: MarketDataProviding = StubMarketDataService()) {
        self.service = service
        self.quotes = service.loadQuotes()
    }

    func reload() {
        quotes = service.loadQuotes()
    }

    var visibleQuotes: [Quote] {
        sorted(filtered(quotes, matching: searchText))
    }

    func filtered(_ input: [Quote], matching query: String) -> [Quote] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return input }
        return input.filter {
            $0.symbol.localizedCaseInsensitiveContains(trimmed)
                || $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func sorted(_ input: [Quote]) -> [Quote] {
        switch sort {
        case .symbol:
            return input.sorted { $0.symbol < $1.symbol }
        case .topMovers:
            return input.sorted { $0.changePercent > $1.changePercent }
        }
    }

    func toggleSort() {
        sort = sort == .symbol ? .topMovers : .symbol
    }

    func quote(for symbol: String) -> Quote? {
        quotes.first { $0.symbol == symbol }
    }
}
