# OTPKit

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-Supported-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://github.com/OneBusAway/otpkit/actions/workflows/ci.yml/badge.svg)](https://github.com/OneBusAway/otpkit/actions)

![otpkit-showcase](https://github.com/user-attachments/assets/c5f819f0-4803-4a6e-86df-55f2677499c3)

# Introduction
OpenTripPlanner library for iOS, written in Swift.
**OTPKit** is a reusable library that powers trip planning in the [OneBusAway iOS app](https://github.com/OneBusAway/onebusaway-ios) and can be integrated into any iOS application.

- Compatible with **iOS 18+**
- Works with **OpenTripPlanner 1.5.x and higher**
- Licensed under **Apache 2.0**
- Provides networking, models, and APIs for building a complete trip planning experience

## Quick Start

### Installation

Add **OTPKit** to your iOS project using **Swift Package Manager**:

```swift
dependencies: [
    .package(url: "https://github.com/OneBusAway/OTPKit.git", from: "1.0.0")
]
```
### SwiftUI Usage
```swift
import OTPKit
import MapKit

struct ContentView: View {
   var body: some View {
       // 1. Define the search region for location suggestions
       let searchRegion = MKCoordinateRegion(
           center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
           latitudinalMeters: 50000,
           longitudinalMeters: 50000
       )

       // 2. Configure OTPKit with server URL, theme, and search region
       let config = OTPConfiguration(
           otpServerURL: URL(string: "https://your-otp-server.com")!,
           themeConfiguration: OTPThemeConfiguration(primaryColor: .blue, secondaryColor: .gray),
           searchRegion: searchRegion
       )

       // 3. Create API service for OpenTripPlanner
       let apiService = RestAPIService(baseURL: config.otpServerURL)

       VStack {
           // 4. Add complete trip planner to your app
           OTPView(otpConfig: config, apiService: apiService)
       }
   }
}
```

### UIKit Usage

```swift
import OTPKit
import MapKit

// Define the search region for location suggestions
let searchRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
    latitudinalMeters: 50000,
    longitudinalMeters: 50000
)

let config = OTPConfiguration(
    otpServerURL: URL(string: "https://your-otp-server.com")!,
    searchRegion: searchRegion
)

let apiService = RestAPIService(baseURL: config.otpServerURL)
let tripPlannerView = OTPView(otpConfig: config, apiService: apiService)

// Embed in UIKit using UIHostingController
let hostingController = UIHostingController(rootView: tripPlannerView)
addChild(hostingController)
view.addSubview(hostingController.view)
```

## Development

### SwiftLint

OTPKit uses [SwiftLint](https://github.com/realm/SwiftLint) to enforce consistent code style and Swift best practices.
Install it locally using Homebrew:

```bash
brew install swiftlint
```

### Pre-commit Hooks

The project uses [pre-commit](https://pre-commit.com) to automatically run SwiftLint and tests before pushing to GitHub.

```bash
# Install pre-commit (first time setup)
brew install pre-commit

# Install the git hook scripts for pre-push
pre-commit install --hook-type pre-push

# (Optional) Run against all files manually
pre-commit run --all-files --hook-stage pre-push
```

Once installed, the following checks will run automatically before each push:
1. **SwiftLint** - Code style and best practices validation
2. **Xcode Tests** - Full test suite must pass

If either linting or tests fail, the push will be blocked until issues are fixed.

<hr>

## About the project

This project was developed as part of **[Google Summer of Code 2025](https://summerofcode.withgoogle.com/programs/2025/projects/7hA4Gs1k)**, created by **Manu Rajbhar** with guidance from **Aaron Brethorst**.

You can read the full final report here: [GSoC 2025 Final Report – OTPKit](https://gist.github.com/manu-r12/cf10fd8c05bc0cab2ca258953e3f8b2b)

# License

Licensed under Apache 2.0. See LICENSE for more details.

# Contributors

* [Aaron Brethorst](https://github.com/aaronbrethorst)
* [Manu R](https://github.com/manu-r12) - GSoC 2025 contributor
* [Hilmy Veradin](https://github.com/hilmyveradin) - GSoC 2024 contributor