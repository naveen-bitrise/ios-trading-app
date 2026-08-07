import Foundation

/// Locale-independent formatting so the UI (and the tests asserting on it) stay stable.
enum PriceFormatter {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        // Pinned to en_US so prices render identically on any device locale,
        // which keeps the UI test assertions stable.
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func currency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func signedCurrency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : "+"
        return sign + currency(abs(value))
    }

    static func signedPercent(_ value: Double) -> String {
        let sign = value < 0 ? "-" : "+"
        return String(format: "%@%.2f%%", sign, abs(value))
    }

    static func quantity(_ value: Int) -> String {
        "\(value) sh"
    }
}
