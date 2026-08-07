import XCTest
@testable import TradingApp

private struct FixedMarketDataService: MarketDataProviding {
    let quotes: [Quote]
    func loadQuotes() -> [Quote] { quotes }
}

final class WatchlistViewModelTests: XCTestCase {
    /// Deliberately ordered so that alphabetical and top-mover order differ.
    private let quotes = [
        Quote(symbol: "AAPL", name: "Apple Inc.", price: 90, previousClose: 100),      // -10%
        Quote(symbol: "TSLA", name: "Tesla Inc.", price: 110, previousClose: 100),     // +10%
        Quote(symbol: "MSFT", name: "Microsoft Corp.", price: 105, previousClose: 100) // +5%
    ]

    private func makeViewModel() -> WatchlistViewModel {
        WatchlistViewModel(service: FixedMarketDataService(quotes: quotes))
    }

    func testLoadsQuotesFromService() {
        XCTAssertEqual(makeViewModel().quotes.count, 3)
    }

    func testDefaultSortIsAlphabeticalBySymbol() {
        XCTAssertEqual(makeViewModel().visibleQuotes.map(\.symbol), ["AAPL", "MSFT", "TSLA"])
    }

    func testTopMoversSortIsByChangePercentDescending() {
        let viewModel = makeViewModel()
        viewModel.toggleSort()
        XCTAssertEqual(viewModel.sort, .topMovers)
        XCTAssertEqual(viewModel.visibleQuotes.map(\.symbol), ["TSLA", "MSFT", "AAPL"])
    }

    func testToggleSortReturnsToSymbolOrder() {
        let viewModel = makeViewModel()
        viewModel.toggleSort()
        viewModel.toggleSort()
        XCTAssertEqual(viewModel.sort, .symbol)
    }

    func testSearchMatchesSymbolCaseInsensitively() {
        let viewModel = makeViewModel()
        viewModel.searchText = "aapl"
        XCTAssertEqual(viewModel.visibleQuotes.map(\.symbol), ["AAPL"])
    }

    func testSearchMatchesCompanyName() {
        let viewModel = makeViewModel()
        viewModel.searchText = "micro"
        XCTAssertEqual(viewModel.visibleQuotes.map(\.symbol), ["MSFT"])
    }

    func testWhitespaceOnlySearchReturnsEverything() {
        let viewModel = makeViewModel()
        viewModel.searchText = "   "
        XCTAssertEqual(viewModel.visibleQuotes.count, 3)
    }

    func testUnmatchedSearchReturnsNoQuotes() {
        let viewModel = makeViewModel()
        viewModel.searchText = "ZZZZ"
        XCTAssertTrue(viewModel.visibleQuotes.isEmpty)
    }

    func testQuoteLookupBySymbol() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.quote(for: "MSFT")?.name, "Microsoft Corp.")
        XCTAssertNil(viewModel.quote(for: "NOPE"))
    }
}
