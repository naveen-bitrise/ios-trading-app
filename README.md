# ios-trading-app

A small SwiftUI trading app used to exercise Bitrise CI: unit tests, UI tests with
screenshot and video attachments, and a simulator build artifact.

## The app

Two screens, no network access (market data is a deterministic stub so tests are stable):

| Screen | What it does |
| --- | --- |
| **Watchlist** (`WatchlistView`) | Buying power, search by symbol or company name, sort by symbol or top movers, and your open positions with unrealized P&L. |
| **Order ticket** (`TradeTicketView`) | Buy/sell, market or limit order, quantity stepper, live estimated cost, and order placement validated against cash and shares held. |

Business logic lives in `PortfolioStore`, `OrderTicketViewModel` and `WatchlistViewModel`.

## Project layout

```
TradingApp/            app sources (SwiftUI)
TradingAppTests/       XCTest unit tests
TradingAppUITests/     XCUITest UI tests + ScreenRecorder helper
TestPlans/             UnitTests.xctestplan, UITests.xctestplan
bitrise.yml            CI configuration
```

The Xcode project uses file-system-synchronized groups, so new files in those
folders are picked up without editing `project.pbxproj`.

## Running locally

```bash
# unit tests
xcodebuild test -project TradingApp.xcodeproj -scheme TradingApp \
  -testPlan UnitTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# UI tests (screenshots + video attachments)
xcodebuild test -project TradingApp.xcodeproj -scheme TradingApp \
  -testPlan UITests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Bitrise workflows

| Workflow | What it does |
| --- | --- |
| `unit_tests` | Runs the `UnitTests` test plan and publishes the test report. Triggered on pushes to `main` and on pull requests. |
| `ui_tests` | Runs the `UITests` test plan. Screenshots are attached from every test; `VideoUITests` records two flows and attaches them as `.mp4`. |
| `simulator_build` | Builds an unsigned simulator `.app` and uploads `TradingApp-simulator.zip` as a build artifact. |

### Test attachments

Every UI test attaches screenshots with `XCTAttachment(screenshot:)` and
`lifetime = .keepAlways`. `VideoUITests` additionally samples the screen while the
flow runs and encodes the frames into an H.264 `.mp4` with `AVAssetWriter`
(`TradingAppUITests/Support/ScreenRecorder.swift`), attaching it with
`XCTAttachment(contentsOfFile:uniformTypeIdentifier:)`.

Bitrise reads attachments straight out of the `.xcresult`, so `deploy-to-bitrise-io`
is all that is needed to see them next to each test on the build's **Tests** tab —
see [Collating test attachments with test results](https://docs.bitrise.io/en/bitrise-ci/testing/deploying-and-viewing-test-results#collating-test-attachments-with-test-results).

### Installing the simulator artifact

```bash
unzip TradingApp-simulator.zip
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl install booted TradingApp.app
xcrun simctl launch booted io.bitrise.tradingapp
```
