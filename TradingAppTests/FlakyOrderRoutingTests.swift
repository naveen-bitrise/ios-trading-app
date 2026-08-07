import XCTest
@testable import TradingApp

/// A deliberately flaky test, used to exercise the `retry_on_failure` setting
/// on the `unit_tests` Bitrise workflow.
///
/// It simulates the classic flake: an order is placed, but the routing
/// acknowledgement has not landed by the time the assertion runs. Rather than
/// failing at random — which could burn all three attempts and turn the build
/// red — it fails on the *first* execution on a given machine and passes on any
/// later one. The observable behaviour on CI is the same as a genuine flake:
/// the first attempt fails, a retry passes, and Bitrise reports the test as
/// flaky via `BITRISE_FLAKY_TEST_CASES`.
final class FlakyOrderRoutingTests: XCTestCase {
    /// Survives the process relaunch that happens between test repetitions.
    private var attemptCounterURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("flaky-order-routing-attempts.txt")
    }

    /// Attempts within one test run are minutes apart at most, so a counter
    /// older than that belongs to a previous run and is discarded — otherwise
    /// the test would stop flaking on any machine that has run it before.
    private static let counterLifetime: TimeInterval = 300

    private func recordAttempt() -> Int {
        let url = attemptCounterURL
        let modifiedAt = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        let isStale = modifiedAt.map { Date().timeIntervalSince($0) > Self.counterLifetime } ?? true

        let previous = isStale ? 0 : (try? String(contentsOf: url, encoding: .utf8))
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? 0
        let attempt = previous + 1
        try? String(attempt).write(to: url, atomically: true, encoding: .utf8)
        return attempt
    }

    func testMarketOrderRoutingAcknowledgementArrives() {
        let attempt = recordAttempt()

        let store = PortfolioStore(cash: 1_000)
        let order = Order(
            symbol: "AAPL",
            side: .buy,
            type: .market,
            quantity: 2,
            limitPrice: nil,
            executionPrice: 100
        )
        store.submit(order)

        XCTAssertEqual(store.heldQuantity(for: "AAPL"), 2)
        XCTAssertEqual(store.cash, 800, accuracy: 0.0001)

        XCTAssertGreaterThan(
            attempt,
            1,
            "Simulated flake on attempt \(attempt): the routing acknowledgement had not arrived yet."
        )
    }
}
