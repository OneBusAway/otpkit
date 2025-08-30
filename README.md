# OTPKit

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-Supported-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://github.com/OneBusAway/otpkit/actions/workflows/ci.yml/badge.svg)](https://github.com/OneBusAway/otpkit/actions)


![otpkit-showcase](https://github.com/user-attachments/assets/c5f819f0-4803-4a6e-86df-55f2677499c3)



# Introduction
OpenTripPlanner library for iOS, written in Swift.
**OTPKit** is a reusable library that powers trip planning in the [OneBusAway iOS app](https://onebusaway.org/) and can be integrated into any iOS application.  

- Compatible with **iOS 17+**  
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

struct ContentView: View {
   var body: some View {
       // 1. Configure OTPKit with server URL and theme
       let config = OTPConfiguration(
           otpServerURL: URL(string: "https://your-otp-server.com")!,
           region: .userLocation(fallback: .automatic),
           themeConfiguration: OTPThemeConfiguration(primaryColor: .blue, secondaryColor: .gray)
       )
       
       // 2. Create API service for OpenTripPlanner
       let apiService = RestAPIService(baseURL: config.otpServerURL)
       
       VStack {
           // 3. Add complete trip planner to your app
           OTPView(otpConfig: config, apiService: apiService)
       }
   }
}
```

### UIKit Usage

```swift
import OTPKit

let config = OTPConfiguration(
    otpServerURL: URL(string: "https://your-otp-server.com")!,
    region: .userLocation(fallback: .automatic)
)

let apiService = RestAPIService(baseURL: config.otpServerURL)
let tripPlannerView = OTPView(otpConfig: config, apiService: apiService)

// Embed in UIKit using UIHostingController
let hostingController = UIHostingController(rootView: tripPlannerView)
addChild(hostingController)
view.addSubview(hostingController.view)

```

### SwiftLint

OTPKit uses [SwiftLint](https://github.com/realm/SwiftLint) to enforce consistent code style and Swift best practices.  
Install it locally using Homebrew:

```bash
brew install swiftlint
```

<hr>


## About the project


This project was developed as part of **[Google Summer of Code 2025](https://summerofcode.withgoogle.com/programs/2025/projects/7hA4Gs1k)**, created by **Manu Rajbhar** with guidance from **Aaron Brethorst**.  


### Google Summer of Code 2025 Final Report

**Project:** Build a Trip Planner for OneBusAway iOS  
**Organization:** Open Transit Software Foundation  
**Contributor:** Manu Rajbhar  
**Mentor:** Aaron Brethorst  
**Project Duration:** May – August 2025  

### Project Goals
The goal was to build the first **Apache 2.0-licensed trip planning library** for the **OneBusAway iOS app** to help *hundreds of thousands of people* reach their destinations, while also delivering a **reusable Swift Package (OTPKit)** for any iOS app. The goal also included creating a **production-quality trip planning framework** built in **Swift** and **SwiftUI**, designed for both reusability and real-world deployment.

### What Was Done
- Main objectives were accomplished  
- Developed a fully working iOS library (OTPKit) for trip planning  
- Successfully integrated into the OneBusAway iOS app  

### Current State
OTPKit is now available for testing via the **OTPKitDemo** app and has been successfully integrated into the **OneBusAway iOS app**, where it can also be tested. It supports both **SwiftUI** and **UIKit** integration, includes support for the **REST API of OpenTripPlanner**, and currently provides approximately **95% localization coverage**.  

### What's Left To Do
Next steps include adding GraphQL support for OTP 2.x, extending multi-modal support, collecting feedback, making minor UI improvements, expanding localization coverage (currently ~95%), adding more test coverage for edge cases, and exploring possible support for real-time GTFS-RT.

### Upstream Status
OTPKit has been successfully integrated upstream into the **OneBusAway iOS app** 
#### Pull Requests

**Main Integration into OneBusAway iOS**  
- [PR #832 – Trip Planner Integration](https://github.com/OneBusAway/onebusaway-ios/pull/832)

**OTPKit Codebase Improvements**  
- [PR #101](https://github.com/OneBusAway/otpkit/pull/101)  
- [PR #100](https://github.com/OneBusAway/otpkit/pull/100)  
- [PR #99](https://github.com/OneBusAway/otpkit/pull/99)  
- [PR #98](https://github.com/OneBusAway/otpkit/pull/98)  
- [PR #97](https://github.com/OneBusAway/otpkit/pull/97)  
- [PR #96](https://github.com/OneBusAway/otpkit/pull/96)  
- [PR #95](https://github.com/OneBusAway/otpkit/pull/95)  
- [PR #92](https://github.com/OneBusAway/otpkit/pull/92)  
- [PR #91](https://github.com/OneBusAway/otpkit/pull/91)  
- [PR #89](https://github.com/OneBusAway/otpkit/pull/89)  
- [PR #86](https://github.com/OneBusAway/otpkit/pull/86)  
- [PR #85](https://github.com/OneBusAway/otpkit/pull/85)  
- [PR #84](https://github.com/OneBusAway/otpkit/pull/84)    

**Pending**  
- [PR #102 – Apply minor UI improvements, bug fixes, and lint warning cleanups](https://github.com/OneBusAway/otpkit/pull/102)

### Challenges & Learnings
There were several challenges while developing OTPKit, especially aiming to build an Apple-quality framework. The most interesting part was learning about SwiftUI data flow across views and exploring the best architectural patterns. Making mistakes in code and learning from them, improving modularity in the codebase, and finding the balance between “perfect” and “good enough” in open-source development were some of the key learnings.  
