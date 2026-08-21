# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OTPKit is an OpenTripPlanner client library for iOS (a OneBusAway / Open Transit Software Foundation project). It provides networking, models, and a complete SwiftUI trip-planning UI that host apps embed over their own map view. Supports OTP 1.x (REST) and OTP 2.x (GTFS GraphQL) servers.

Layout:
- `Package.swift` (repo root) — Swift package; sources at `OTPKit/Sources`, tests at `OTPKit/Tests`. iOS 18+, swift-tools 6.0, but `swiftLanguageModes: [.v5]`.
- `Demo/OTPKitDemo.xcodeproj` — UIKit demo app that depends on the local package.
- Dependencies: SwiftUI-Flow (library), ViewInspector (tests only).

The package is iOS-only (SwiftUI/MapKit/UIKit APIs) — `swift build` / `swift test` on macOS will not work. Always build through xcodebuild with a simulator destination.

## Commands

```bash
# Run all package tests
xcodebuild test -scheme OTPKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run a single test file/suite (tests are mostly Swift Testing, a couple XCTest)
xcodebuild test -scheme OTPKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:OTPKitTests/TripPlannerViewModelTests

# Lint — CI runs strict mode and fails the build before tests even run
swiftlint --strict
swiftlint --fix
```

CI (`.github/workflows/test.yaml`) runs `swiftlint --strict`, then build-for-testing/test-without-building on **Xcode 26.2**. A local Xcode beta may be newer and more lenient about implicit framework imports — add explicit `import CoreLocation` / `import MapKit` etc. where symbols are used, or CI will fail on code that builds locally.

SwiftLint config is `.swiftlint.yml` (root), with additional rules disabled for tests in `OTPKit/Tests/.swiftlint.yml`.

Optional pre-push hooks via pre-commit (`pre-commit install --hook-type pre-push`) run strict SwiftLint plus the full test suite.

## Architecture

### Entry point and ownership model

`TripPlanner` (`OTPKit/Sources/OTPKit/Presentation/TripPlanner.swift`, `@MainActor`) is the public facade. The host app constructs it with three things it owns:

1. `OTPConfiguration` — server URL, enabled transport modes, theme (`OTPThemeConfiguration`), and a required `searchRegion` (`MKCoordinateRegion`) that scopes location search.
2. An `APIService` implementation.
3. An `OTPMapProvider` implementation.

`TripPlanner` internally wires up `MapCoordinator` and `TripPlannerViewModel`, and `createTripPlannerView(origin:destination:viaPoint:transportMode:chrome:onClose:)` returns the SwiftUI UI (`TripPlannerView`), which the demo hosts in a `PanelHostingController` bottom sheet. `chrome` (`TripPlannerChrome`) decides whether the planner supplies its own `NavigationStack`, title and close button (`.standalone`, the default) or renders the body alone inside navigation the host owns (`.embedded`); an embedded host owns dismissal, leaves `onClose` nil, and calls `TripPlanner.reset()` when it dismisses. Cross-object events flow through `NotificationCenter` (injectable; see `Core/Notifications.swift`).

### The map is inversion-of-control

OTPKit never creates a map. The host app owns the map view and hands OTPKit an `OTPMapProvider` (protocol in `Core/Map/OTPMapProvider.swift`) — `MKMapViewAdapter` is the provided MapKit implementation. All map mutations (routes, annotations, camera) go through `MapCoordinator`, which is the only thing that talks to the provider.

### Networking (`OTPKit/Sources/OTPKit/Network/`)

`APIService` is the protocol for trip planning; both implementations are actors:
- `RestAPIService` — OTP 1.x REST `/plan` API.
- `GraphQLAPIService` — OTP 2.x GTFS GraphQL `plan` query (`GraphQLPlanResponse` for decoding).

The demo picks REST vs GraphQL per region (`OTPRegionInfo.apiType`). Requests go through `URLDataLoader`, which tests replace with `MockDataLoader` to serve JSON fixtures.

Vehicle rental (bikeshare/scooter) is a separate stack: `VehicleRentalSource` (protocol) / `VehicleRentalService` (GraphQL implementation, Sendable) fetch rental stations and free-floating vehicles, filterable by `VehicleFormFactor`. Rental-aware planning uses `viaPoint` on `createTripPlannerView` ("plan a trip using this bike"); OTP servers may require a transit mode (`.transitBikeRental`, not `.bikeRental`) to route through a via point.

### State management

`TripPlannerViewModel` (`ObservableObject`, main-actor) is the single source of truth for the planning flow: origin/destination selection, plan requests via `APIService`, itinerary/leg selection, and driving `MapCoordinator`. Views in `Presentation/` (Sheets for search/directions/advanced options, TopControls, Buttons) all observe it. `Core/TripProgress/` computes live progress along an active itinerary. `UserDefaultsServices` (`Core/Services/`) persists recent locations.

### Tests (`OTPKit/Tests/`)

Predominantly Swift Testing (`@Test`); `RestAPIServiceTests`/comprehensive tests still use XCTest. JSON fixtures live in `OTPKit/Tests/Fixtures` (copied as a package resource) and load via `Helpers/Fixtures.swift`. `MockDataLoader` stubs the network; `MockMapProvider` stubs the map. `LocalizationTests` verifies the 13 `.lproj` string tables in `Resources/` stay in sync — new user-facing strings must be added to all of them.
