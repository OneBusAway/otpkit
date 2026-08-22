# OTPKit

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-18.0%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-Supported-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://github.com/OneBusAway/otpkit/actions/workflows/test.yaml/badge.svg)](https://github.com/OneBusAway/otpkit/actions)

A modern [OpenTripPlanner](https://www.opentripplanner.org) client for iOS, written in Swift and SwiftUI. OTPKit gives your app a complete, production-quality trip planning experience — search, itineraries, turn-by-turn directions, live trip progress — rendered on top of a map view that *you* own. It powers trip planning in the [OneBusAway iOS app](https://github.com/OneBusAway/onebusaway-ios) and is a project of the [Open Transit Software Foundation](https://opentransitsoftwarefoundation.org).

![otpkit-showcase](https://github.com/user-attachments/assets/c5f819f0-4803-4a6e-86df-55f2677499c3)

**Jump to what you're here for:**

- [Add trip planning to your iOS app](#add-trip-planning-to-your-app)
- [See it running in five minutes](#see-it-running-the-demo-app)
- [Contribute to the project](#contributing)

## Why OTPKit?

- **Complete UI, not just a networking layer.** Origin/destination search, transport mode selection, itinerary comparison, step-by-step directions, and live progress along an active trip — all included, all SwiftUI, localized into 13 languages.
- **Bring your own map.** OTPKit draws routes and annotations through a small `OTPMapProvider` protocol. Use the bundled `MKMapViewAdapter` for MapKit, or implement the protocol to keep your existing map stack.
- **Works with both OTP generations.** OTP 1.x (REST) and OTP 2.x (GTFS GraphQL) behind a single `APIService` protocol — pick the implementation that matches your server and the rest of your code doesn't change.
- **Shared-mobility aware.** On OTP 2.x servers, OTPKit can fetch bike/scooter share stations and free-floating vehicles and plan rental-aware trips ("get me there using this bike").
- **Proven in production.** This is the trip planner inside OneBusAway iOS, exercised daily by real riders.

### Requirements

| | |
|---|---|
| iOS | 18.0+ |
| Swift | 6.0 toolchain (package builds in Swift 5 language mode) |
| Server | OpenTripPlanner 1.5.x+ (REST) or 2.x (GTFS GraphQL) |

## Add trip planning to your app

### 1. Install

Add OTPKit with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/OneBusAway/OTPKit.git", from: "0.16.0")
]
```

OTPKit is pre-1.0: releases are tagged and safe to pin, but the API may still change between minor versions.

### 2. Integrate

Three pieces wire together: a **map provider** (adapting the map view you own), an **API service** (matching your OTP server's generation), and a **`TripPlanner`** (which builds the UI). Here's the complete setup in a UIKit view controller, matching what the demo app does:

```swift
import MapKit
import OTPKit
import SwiftUI
import UIKit

class ViewController: UIViewController {
    private var tripPlanner: TripPlanner?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. You own the map view; give OTPKit an adapter for it.
        let mapView = MKMapView(frame: view.bounds)
        view.addSubview(mapView)
        let mapProvider = MKMapViewAdapter(mapView: mapView)

        // 2. Point OTPKit at your server, and scope location search
        //    to your service area.
        let config = OTPConfiguration(
            otpServerURL: URL(string: "https://otp.example.com/otp/")!,
            searchRegion: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        )

        // 3. Pick the service that matches your server:
        //    RestAPIService for OTP 1.x, GraphQLAPIService for OTP 2.x.
        let apiService = RestAPIService(baseURL: config.otpServerURL)

        // 4. Create the planner and present its UI as a bottom sheet.
        let planner = TripPlanner(
            otpConfig: config,
            apiService: apiService,
            mapProvider: mapProvider
        )
        let plannerView = planner.createTripPlannerView { [weak self] in
            self?.dismiss(animated: true)
        }
        present(PanelHostingController(rootView: plannerView, sourceView: view), animated: true)
        tripPlanner = planner
    }
}
```

`createTripPlannerView` returns a plain SwiftUI view, so you're not locked into the bottom-sheet presentation — host it however your app's navigation works. It also accepts optional prefill parameters (`origin`, `destination`, `viaPoint`, `transportMode`) for deep-linking straight into a planned trip.

If you're presenting the planner inside navigation you already own, pass `chrome: .embedded` so OTPKit doesn't add a second header and close button:

```swift
.sheet(isPresented: $showingPlanner, onDismiss: { planner.reset() }) {
    NavigationStack {
        planner.createTripPlannerView(chrome: .embedded)
            .navigationTitle("Plan a trip")
    }
}
```

An embedded planner has no close button of its own, so dismissal is yours to handle: leave `onClose` nil and call `TripPlanner.reset()` at your dismissal point, or the next presentation reopens on the previous trip.

### Which API service do I use?

| Your OTP server | Use | Notes |
|---|---|---|
| OTP 1.x (REST `/plan` endpoint) | `RestAPIService` | |
| OTP 2.x (GTFS GraphQL API) | `GraphQLAPIService` | Required for bike/scooter rental features |

Both are Swift actors conforming to `APIService`; you can also implement `APIService` yourself to add authentication, caching, or a custom backend.

### Customizing

- **Transport modes:** pass `enabledTransportModes` to `OTPConfiguration` (defaults to transit, walk, bike, car). Rental modes like `.bikeRental` are opt-in and need an OTP 2.x server with rental data.
- **Theme:** pass an `OTPThemeConfiguration` to adjust colors.
- **Map behavior:** implement `OTPMapProvider` to control exactly how routes and stops render on your map. The protocol is `@MainActor`, so conformances inherit main-actor isolation — write your provider as main-actor isolated rather than opting the conformance out.

### Localization

OTPKit ships translations for Arabic, English, Filipino, French, Italian, Korean, Polish, Portuguese (Brazil), Russian, Simplified Chinese, Spanish, Traditional Chinese, and Vietnamese.

**Your app must declare which of these languages it supports, or OTPKit will render in English.** iOS resolves an app's language from the *main* bundle, so a host app that ships no localizations pins the whole process to English regardless of the device language. If your app is already localized into the languages you care about, there's nothing to do. Otherwise, declare them in your app target's `Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>ar</string>
    <string>es</string>
    <string>fil</string>
    <string>fr</string>
    <string>it</string>
    <string>ko</string>
    <string>pl</string>
    <string>pt-BR</string>
    <string>ru</string>
    <string>vi</string>
    <string>zh-Hans</string>
    <string>zh-Hant</string>
</array>
```

OTPKit resolves strings from its own resource bundle, so redefining the same keys in your app's `Localizable.strings` will not override them. To change or add wording, edit [`OTPKit/Sources/OTPKit/Resources/en.lproj/Localizable.strings`](OTPKit/Sources/OTPKit/Resources/en.lproj/Localizable.strings) and its sibling locales.

## See it running: the demo app

No configuration needed — the demo ships with working public OTP servers:

```bash
git clone https://github.com/OneBusAway/otpkit.git
cd otpkit
open Demo/OTPKitDemo.xcodeproj
```

Run the **OTPKitDemo** scheme on an iOS simulator, then pick a region on first launch:

- **San Diego** — OTP 1.x REST
- **Seattle** — OTP 1.x REST
- **Seattle (OTP 2.x GraphQL)** — the GraphQL API, including bike share

Tip: set the simulator's location (Features → Location) to somewhere inside the region you picked so "current location" trip planning works.

## Contributing

Issues and pull requests are welcome. The library lives in `OTPKit/` (sources and tests) with `Package.swift` at the repo root; the demo app lives in `Demo/`.

### Build and test

The package uses iOS-only frameworks, so build and test through Xcode (not `swift test`):

```bash
# Run the test suite
xcodebuild test -scheme OTPKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Lint

CI runs SwiftLint in strict mode and fails fast, so run it before pushing:

```bash
brew install swiftlint
swiftlint --strict
```

### Pre-push hooks (recommended)

[pre-commit](https://pre-commit.com) can run SwiftLint and the test suite automatically before every push:

```bash
brew install pre-commit
pre-commit install --hook-type pre-push
```

## About the project

OTPKit began as a **Google Summer of Code** project and continues to grow with each cohort:

- [GSoC 2025](https://summerofcode.withgoogle.com/programs/2025/projects/7hA4Gs1k): built by **[Manu R](https://github.com/manu-r12)** with mentorship from **[Aaron Brethorst](https://github.com/aaronbrethorst)** — read the [final report](https://gist.github.com/manu-r12/cf10fd8c05bc0cab2ca258953e3f8b2b)
- GSoC 2024: **[Hilmy Veradin](https://github.com/hilmyveradin)**

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
