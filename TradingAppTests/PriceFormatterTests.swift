import XCTest
@testable import TradingApp

final class PriceFormatterTests: XCTestCase {
    func testCurrencyFormatsWithTwoDecimals() {
        XCTAssertEqual(PriceFormatter.currency(224.5), "$224.50")
        XCTAssertEqual(PriceFormatter.currency(0), "$0.00")
    }

    func testCurrencyGroupsThousands() {
        XCTAssertEqual(PriceFormatter.currency(25_000), "$25,000.00")
        XCTAssertEqual(PriceFormatter.currency(1_234_567.89), "$1,234,567.89")
    }

    func testCurrencyRoundsToNearestCent() {
        XCTAssertEqual(PriceFormatter.currency(10.006), "$10.01")
        XCTAssertEqual(PriceFormatter.currency(10.004), "$10.00")
    }

    func testSignedCurrencyPrefixesSign() {
        XCTAssertEqual(PriceFormatter.signedCurrency(4.4), "+$4.40")
        XCTAssertEqual(PriceFormatter.signedCurrency(-3.55), "-$3.55")
    }

    func testSignedPercentPrefixesSign() {
        XCTAssertEqual(PriceFormatter.signedPercent(1.9991), "+2.00%")
        XCTAssertEqual(PriceFormatter.signedPercent(-0.842), "-0.84%")
    }

    func testQuantityFormatting() {
        XCTAssertEqual(PriceFormatter.quantity(12), "12 sh")
    }
}
