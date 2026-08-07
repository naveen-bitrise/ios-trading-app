import XCTest
@testable import TradingApp

final class PositionTests: XCTestCase {
    func testAddingSharesSetsAverageCost() {
        var position = Position(symbol: "AAPL")
        position.add(quantity: 10, at: 100)
        XCTAssertEqual(position.quantity, 10)
        XCTAssertEqual(position.averageCost, 100, accuracy: 0.0001)
    }

    func testAddingMoreSharesBlendsAverageCost() {
        var position = Position(symbol: "AAPL")
        position.add(quantity: 10, at: 100)
        position.add(quantity: 10, at: 200)
        XCTAssertEqual(position.quantity, 20)
        XCTAssertEqual(position.averageCost, 150, accuracy: 0.0001)
    }

    func testRemovingSharesKeepsAverageCost() {
        var position = Position(symbol: "AAPL", quantity: 10, averageCost: 100)
        position.remove(quantity: 4)
        XCTAssertEqual(position.quantity, 6)
        XCTAssertEqual(position.averageCost, 100, accuracy: 0.0001)
    }

    func testRemovingAllSharesClearsAverageCost() {
        var position = Position(symbol: "AAPL", quantity: 10, averageCost: 100)
        position.remove(quantity: 10)
        XCTAssertEqual(position.quantity, 0)
        XCTAssertEqual(position.averageCost, 0)
    }

    func testRemovingMoreThanHeldFloorsAtZero() {
        var position = Position(symbol: "AAPL", quantity: 3, averageCost: 100)
        position.remove(quantity: 10)
        XCTAssertEqual(position.quantity, 0)
    }

    func testMarketValueAndUnrealizedPnL() {
        let position = Position(symbol: "AAPL", quantity: 10, averageCost: 100)
        XCTAssertEqual(position.costBasis, 1_000, accuracy: 0.0001)
        XCTAssertEqual(position.marketValue(at: 120), 1_200, accuracy: 0.0001)
        XCTAssertEqual(position.unrealizedPnL(at: 120), 200, accuracy: 0.0001)
        XCTAssertEqual(position.unrealizedPnL(at: 80), -200, accuracy: 0.0001)
    }
}
