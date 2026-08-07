import SwiftUI

/// Screen 2 — the order ticket: pick a side, an order type, a size, review the
/// estimated cost and place the order against the portfolio.
struct TradeTicketView: View {
    @EnvironmentObject private var portfolio: PortfolioStore
    @StateObject private var viewModel: OrderTicketViewModel

    /// The portfolio is passed explicitly because `@EnvironmentObject` is not
    /// readable from `init`, and the view model needs it up front.
    init(quote: Quote, portfolio: PortfolioStore) {
        _viewModel = StateObject(wrappedValue: OrderTicketViewModel(quote: quote, portfolio: portfolio))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                priceHeader
                sideSelector
                orderTypeSelector
                if viewModel.orderType == .limit {
                    limitPriceField
                }
                quantityStepper
                summaryCard
                placeOrderButton
                if let status = viewModel.statusMessage {
                    Text(status)
                        .font(.footnote.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(viewModel.isError ? Color.red : Color.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill((viewModel.isError ? Color.red : Color.green).opacity(0.12))
                        )
                        .accessibilityIdentifier("ticket.status")
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.quote.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("ticket.screen")
    }

    private var priceHeader: some View {
        VStack(spacing: 4) {
            Text(viewModel.quote.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(PriceFormatter.currency(viewModel.quote.price))
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .accessibilityIdentifier("ticket.price")
            Text("\(PriceFormatter.signedCurrency(viewModel.quote.change)) (\(PriceFormatter.signedPercent(viewModel.quote.changePercent)))")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(viewModel.quote.isUp ? Color.green : Color.red)
                .accessibilityIdentifier("ticket.change")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sideSelector: some View {
        HStack(spacing: 12) {
            ForEach(OrderSide.allCases) { side in
                Button {
                    viewModel.setSide(side)
                } label: {
                    Text(side.rawValue)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.side == side
                                      ? (side == .buy ? Color.green : Color.red)
                                      : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(viewModel.side == side ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ticket.side.\(side.rawValue.lowercased())")
            }
        }
    }

    private var orderTypeSelector: some View {
        HStack(spacing: 12) {
            ForEach(OrderType.allCases) { type in
                Button {
                    viewModel.setOrderType(type)
                } label: {
                    Text(type.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.orderType == type
                                      ? Color.accentColor.opacity(0.2)
                                      : Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.orderType == type ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ticket.orderType.\(type.rawValue.lowercased())")
            }
        }
    }

    private var limitPriceField: some View {
        HStack {
            Text("Limit price")
                .font(.subheadline.weight(.semibold))
            Spacer()
            TextField("0.00", text: $viewModel.limitPriceText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit())
                .frame(width: 120)
                .accessibilityIdentifier("ticket.limitPrice")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quantityStepper: some View {
        HStack {
            Text("Quantity")
                .font(.subheadline.weight(.semibold))
            Spacer()
            HStack(spacing: 20) {
                Button {
                    viewModel.decrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ticket.quantity.decrement")

                Text("\(viewModel.quantity)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .frame(minWidth: 44)
                    .accessibilityIdentifier("ticket.quantity")

                Button {
                    viewModel.increment()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ticket.quantity.increment")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var summaryCard: some View {
        VStack(spacing: 10) {
            summaryRow(
                title: "Estimated \(viewModel.side == .buy ? "cost" : "credit")",
                value: PriceFormatter.currency(viewModel.estimatedCost),
                identifier: "ticket.estimatedCost"
            )
            Divider()
            summaryRow(
                title: "Buying power",
                value: PriceFormatter.currency(portfolio.cash),
                identifier: "ticket.buyingPower"
            )
            Divider()
            summaryRow(
                title: "Shares held",
                value: "\(portfolio.heldQuantity(for: viewModel.quote.symbol))",
                identifier: "ticket.held"
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func summaryRow(title: String, value: String, identifier: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .accessibilityIdentifier(identifier)
        }
    }

    private var placeOrderButton: some View {
        Button {
            viewModel.placeOrder()
        } label: {
            Text("Place \(viewModel.side.rawValue) Order")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.side == .buy ? Color.green : Color.red)
                )
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ticket.placeOrder")
    }
}

#Preview {
    let portfolio = PortfolioStore()
    return NavigationStack {
        TradeTicketView(quote: StubMarketDataService.sampleQuotes[0], portfolio: portfolio)
            .environmentObject(portfolio)
    }
}
