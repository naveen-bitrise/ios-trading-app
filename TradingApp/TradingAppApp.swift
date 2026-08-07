import SwiftUI

/// Test hooks: UI tests launch the app with these environment values so each
/// test starts from a known portfolio state.
enum LaunchConfiguration {
    static var startingCash: Double {
        if let raw = ProcessInfo.processInfo.environment["UITEST_STARTING_CASH"],
           let value = Double(raw) {
            return value
        }
        return PortfolioStore.defaultStartingCash
    }

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITests")
    }
}

@main
struct TradingAppApp: App {
    @StateObject private var portfolio = PortfolioStore(cash: LaunchConfiguration.startingCash)

    var body: some Scene {
        WindowGroup {
            WatchlistView()
                .environmentObject(portfolio)
        }
    }
}
