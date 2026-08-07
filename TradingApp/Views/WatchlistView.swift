import SwiftUI

/// Screen 1 — the market watchlist: search, sort, current positions and a way
/// into the order ticket for any symbol.
struct WatchlistView: View {
    @EnvironmentObject private var portfolio: PortfolioStore
    @StateObject private var viewModel = WatchlistViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                balanceHeader
                searchField
                quoteList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Markets")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Quote.self) { quote in
                TradeTicketView(quote: quote, portfolio: portfolio)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.toggleSort) {
                        Text(viewModel.sort.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .accessibilityIdentifier("watchlist.sortToggle")
                }
            }
        }
    }

    private var balanceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Buying power")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(PriceFormatter.currency(portfolio.cash))
                    .font(.title2.weight(.bold))
                    .accessibilityIdentifier("watchlist.cash")
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Positions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(portfolio.sortedPositions.count)")
                    .font(.title2.weight(.bold))
                    .accessibilityIdentifier("watchlist.positionCount")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search symbol or name", text: $viewModel.searchText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityIdentifier("watchlist.search")
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("watchlist.clearSearch")
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var quoteList: some View {
        List {
            // Holdings come first: they are what you check on open, and it keeps
            // them on screen right after an order fills.
            if !portfolio.sortedPositions.isEmpty {
                Section("Your positions") {
                    ForEach(portfolio.sortedPositions) { position in
                        PositionRow(
                            position: position,
                            price: viewModel.quote(for: position.symbol)?.price ?? position.averageCost
                        )
                        .accessibilityIdentifier("position.\(position.symbol)")
                    }
                }
            }

            Section("Watchlist") {
                if viewModel.visibleQuotes.isEmpty {
                    Text("No symbols match “\(viewModel.searchText)”")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("watchlist.emptyState")
                }
                ForEach(viewModel.visibleQuotes) { quote in
                    NavigationLink(value: quote) {
                        QuoteRow(quote: quote, heldQuantity: portfolio.heldQuantity(for: quote.symbol))
                    }
                    .accessibilityIdentifier("quote.\(quote.symbol)")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

struct QuoteRow: View {
    let quote: Quote
    let heldQuantity: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(quote.symbol)
                    .font(.headline)
                Text(quote.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if heldQuantity > 0 {
                    Text("Holding \(PriceFormatter.quantity(heldQuantity))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(PriceFormatter.currency(quote.price))
                    .font(.headline.monospacedDigit())
                Text(PriceFormatter.signedPercent(quote.changePercent))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(quote.isUp ? Color.green : Color.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PositionRow: View {
    let position: Position
    let price: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.headline)
                Text("\(PriceFormatter.quantity(position.quantity)) @ \(PriceFormatter.currency(position.averageCost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(PriceFormatter.currency(position.marketValue(at: price)))
                    .font(.headline.monospacedDigit())
                Text(PriceFormatter.signedCurrency(position.unrealizedPnL(at: price)))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(position.unrealizedPnL(at: price) < 0 ? Color.red : Color.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchlistView().environmentObject(PortfolioStore())
}
