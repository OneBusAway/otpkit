# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OTPKit is an OpenTripPlanner client library for iOS, supporting OTP 1.x (REST API) and 2.x (GraphQL API). A OneBusAway Project from the Open Transit Software Foundation.

### Project Structure
- **OTPKit**: Swift Package containing the core library (iOS 18+, Swift 6.0)
- **OTPKitDemo**: Demo iOS app (Xcode project) showcasing OTPKit functionality
- **OTPKitDemoTests**: Test suite for the demo app using Swift Testing framework
- **Tests/**: Package-level tests using XCTest

The repository contains both a Swift Package (Package.swift) and an Xcode project (OTPKitDemo.xcodeproj). The Xcode project depends on the local Swift Package.

### API Support Status
- **OTP 1.x REST API**: ✅ Fully implemented via `RestAPIService`
- **OTP 2.x GraphQL API**: ❌ Not yet implemented

## Tests and Quality

### Run Tests
```bash
# Run all tests via Xcode
xcodebuild test -scheme OTPKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Linting & Code Quality
```bash
# Run SwiftLint
swiftlint

# Auto-fix issues
swiftlint --fix

# Install SwiftLint if needed
brew install swiftlint
```

#### Pre-commit Hooks
The project uses [pre-commit](https://pre-commit.com) to automatically run SwiftLint and tests before pushing to GitHub.

```bash
# Install pre-commit (first time setup)
brew install pre-commit

# Install the git hook scripts for pre-push
pre-commit install --hook-type pre-push

# (Optional) Run against all files manually
pre-commit run --all-files
```

Once installed, the following checks will run automatically before each push:
1. **SwiftLint** - Code style and best practices validation
2. **Xcode Tests** - Full test suite must pass

If either linting or tests fail, the push will be blocked until issues are fixed.

## Architecture

### Package Dependencies
- **External**:
  - `SwiftUI-Flow` (from tevelee/SwiftUI-Flow.git, 3.1.0+) - Flow layout for SwiftUI
- **System Frameworks**:
  - SwiftUI (UI components)
  - MapKit (Map display and interactions)
  - CoreLocation (User location services)
  - Foundation (Core utilities)

### Core Components

**OTPKit Package Structure:**
- `Core/` - Core models, configuration, and types
  - `OTPConfiguration` - Main configuration containing server URL, transport modes, and theme
  - `Models/TripPlanner/` - Data models for trip planning
    - `Itinerary` - Complete journey with timing and segments
    - `Leg` - Individual journey segment (walk, transit, etc.)
    - `Place` - Location with coordinates and name
    - `TransportMode` - Available transport options
    - `TripPlanRequest` - Request parameters for trip planning
  - `Helper/Location/` - Location services
    - `LocationManager` - Singleton for CoreLocation integration
    - `SearchManager` - Location search and geocoding
  - `Types/` - Custom error types and enums
  - `Map/` - Map coordination and provider abstraction
    - `OTPMapProvider` - Protocol for external map implementations
    - `MapCoordinator` - Manages map state and operations
    - `MKMapViewAdapter` - MapKit implementation of OTPMapProvider
- `Network/` - API communication layer
  - `APIService` - Protocol defining trip planning interface
  - `RestAPIService/RestAPIService` - OTP 1.x REST API implementation (actor-based)
  - `URLDataLoader` - Network request handling
- `Presentation/` - SwiftUI views and ViewModels
  - `OTPView` - Main entry point view that sets up the environment
  - `TripPlannerView` - Primary UI for trip planning
  - `ViewModel/TripPlannerViewModel` - Main state management (@MainActor)
  - `Sheets/` - Bottom sheet UI components (search, directions, options)
  - `BottomControls/` - Controls for location selection and planning
  - `TopControls/` - Top UI controls
  - `OTPPanel/` - Bottom sheet implementation

### Key Integration Points

1. **Initialization**: Host app provides an `OTPMapProvider` implementation, creates `OTPConfiguration` with server URL, then instantiates `OTPView`
2. **Map Provider**: OTPKit controls an external map view through the `OTPMapProvider` protocol - host app retains ownership of the actual map view
3. **API Service**: Implement `APIService` protocol for custom networking or use provided `RestAPIService`
4. **Location Services**: `LocationManager.shared` handles location permissions and current location updates
5. **Theme Customization**: Configure appearance via `OTPThemeConfiguration` in the config

### Data Flow

1. User interactions in UI views trigger actions in `TripPlannerViewModel`
2. ViewModel calls `APIService` to fetch trip plans from OTP server
3. Response models (OTPResponse, Itinerary, etc.) are decoded and stored in ViewModel
4. UI updates reactively via SwiftUI property wrappers (@Published, @StateObject)
5. Map updates are coordinated through `MapCoordinator` which calls methods on the `OTPMapProvider`

## Development Notes

- Minimum iOS version: 18.0
- Swift version: 6.0
- Swift language mode: Swift 5 (set in Package.swift via `swiftLanguageModes: [.v5]`)
- The package uses SwiftUI and requires iOS platform features (not buildable for macOS due to iOS-specific APIs)
- Location permissions are handled automatically by LocationManager
- The demo app includes an onboarding flow for server configuration
- All models conform to `Codable` for JSON serialization
- Views use `@StateObject`, `@Published`, and `@EnvironmentObject` for reactive updates
- `RestAPIService` is an actor for thread-safe network operations
- `TripPlannerViewModel` is marked `@MainActor` for UI thread safety

## Testing

### Testing Framework
- **OTPKit Package Tests**: Uses XCTest with async/await patterns
- **Demo App Tests**: Uses Swift Testing framework (`@Test` attribute)
- **Test Helpers**: Located in `OTPKitDemoTests/Helpers/`
  - `MockDataLoader` - Mock network responses
  - `Fixtures` - Test data and JSON responses
  - `OTPTestCase` - Base test class with common setup

### Running Tests
```swift
// Example test pattern for API service
func testFetchPlan() async throws {
    let service = RestAPIService(configuration: testConfig)
    let request = TripPlanRequest(/* ... */)
    let response = try await service.fetchPlan(request)
    XCTAssertFalse(response.plan?.itineraries.isEmpty ?? true)
}
```

## Common Integration Scenarios

### Basic Setup
```swift
import OTPKit

// 1. Create your map view (OTPKit doesn't provide one)
let mapView = MKMapView()
let mapProvider = MKMapViewAdapter(mapView: mapView)

// 2. Create configuration
let config = OTPConfiguration(
    otpServerURL: URL(string: "https://otp.example.com")!,
    enabledTransportModes: [.transit, .walk, .bike],
    themeConfiguration: OTPThemeConfiguration(primaryColor: .blue)
)

// 3. Initialize API service
let apiService = RestAPIService(baseURL: config.otpServerURL)

// 4. Create and present OTP view
let otpView = OTPView(
    otpConfig: config,
    apiService: apiService,
    mapProvider: mapProvider
)
```

### Custom Theme Configuration
```swift
let themeConfig = OTPThemeConfiguration(
    primaryColor: .blue,
    secondaryColor: .green,
    backgroundColor: .systemBackground
)
let config = OTPConfiguration(
    otpServerURL: url,
    themeConfiguration: themeConfig
)
```

### Implementing Custom API Service
```swift
public actor CustomAPIService: APIService {
    public func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
        // Custom implementation
        // e.g., add authentication, caching, etc.
    }
}
```

### Implementing Custom Map Provider
```swift
class CustomMapProvider: OTPMapProvider {
    // Implement all required protocol methods
    // to integrate with your preferred mapping solution
    func addRoute(coordinates: [CLLocationCoordinate2D], color: Color, lineWidth: CGFloat, identifier: String) {
        // Add route to your map
    }

    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, identifier: String, type: OTPAnnotationType) {
        // Add marker to your map
    }

    // ... implement remaining protocol methods
}
```

## State Management Patterns

### ViewModel Architecture
- `TripPlannerViewModel` is marked with `@MainActor` for UI thread safety
- Uses `@Published` properties for reactive UI updates
- Async/await for API calls with proper error handling

### Location State Management
```swift
// LocationManager is a singleton
LocationManager.shared.requestLocationPermission()

// Subscribe to location updates
LocationManager.shared.$currentLocation
    .sink { location in
        // Handle location update
    }
```

### Sheet Presentation Pattern
- Sheets are defined in the `Sheet` enum: `.locationOptions`, `.directions`, `.search`, `.advancedOptions`
- Each sheet view is self-contained with its own state

## Code Style & Conventions

### Swift Conventions
- Use Swift 6.0 features (async/await, actors, etc.)
- Follow Swift API Design Guidelines
- Use meaningful variable names (avoid abbreviations)
- Prefer `let` over `var` when possible
- Use trailing closure syntax for single closure parameters
- SwiftLint configuration in `.swiftlint.yml` (disabled rules: `identifier_name`, `todo`; excluded: `OTPKit/.build`)

### SwiftUI Best Practices
- Keep views small and focused (extract subviews)
- Use view modifiers for reusable styling
- Prefer `@StateObject` for view-owned objects
- Use `@EnvironmentObject` for shared state
- Extract complex logic to ViewModels

### File Organization
- Group related files in folders
- Keep protocols and implementations separate
- Place extensions in separate files when substantial
- Use descriptive file names matching the primary type
