import XCTest
@testable import TradingApp

/// A deliberately flaky test, used to exercise the `retry_on_failure` setting
/// on the `unit_tests` Bitrise workflow.
///
/// It simulates the classic flake: an order is placed, but the routing
/// acknowledgement has not landed by the time the assertion runs. Rather than
/// failing at random — which could burn every attempt and turn the build red —
/// it fails on its first execution and passes on the retry. The observable
/// behaviour on CI is the same as a genuine flake: one failure, one retry, a
/// green build, and the test reported through `BITRISE_FLAKY_TEST_CASES`.
///
/// The retry runs in the same process as the original execution (the workflow
/// leaves `relaunch_tests_for_each_repetition` off), so only this test repeats
/// and the counter below is still there on the second attempt.
final class FlakyOrderRoutingTests: XCTestCase {
    private var attemptCounterURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("flaky-order-routing-attempts.txt")
    }

    /// Attempts within one test run are seconds apart, so a counter older than
    /// this belongs to a previous run and is discarded — otherwise the test
    /// would stop flaking on any machine that has already run it.
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
