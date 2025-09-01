# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OTPKit is an OpenTripPlanner client library for iOS, supporting OTP 1.x (REST API) and 2.x (GraphQL API). A OneBusAway Project from the Open Transit Software Foundation.

### Project Structure
- **OTPKit**: Swift Package containing the core library (iOS 17+, Swift 5.9+)
- **OTPKitDemo**: Demo iOS app showcasing OTPKit functionality
- **OTPKitDemoTests**: Test suite for the demo app using Swift Testing framework

### API Support Status
- **OTP 1.x REST API**: ✅ Fully implemented via `RestAPIService`
- **OTP 2.x GraphQL API**: ⚠️ Not yet implemented (placeholder in `GraphQLAPIService`)

## Build Commands

### Build the Demo App
```bash
# Build for iOS Simulator
xcodebuild -project OTPKitDemo.xcodeproj -scheme OTPKitDemo -sdk iphonesimulator build

# Build and run on a specific simulator
xcodebuild -project OTPKitDemo.xcodeproj -scheme OTPKitDemo -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Run Tests

```
xcodebuild -project OTPKitDemo.xcodeproj -scheme OTPKitDemo -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

### Linting & Code Quality
```bash
# The project does not currently have a linter configured
# Consider adding SwiftLint or SwiftFormat if needed
```

## Architecture

### Package Dependencies
- **External**: None (pure Swift implementation)
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
- `Network/` - API communication layer
  - `APIService` - Protocol defining trip planning interface
  - `RestAPIService` - OTP 1.x REST API implementation
  - `GraphQLAPIService` - OTP 2.x GraphQL placeholder (not implemented)
  - `URLDataLoader` - Network request handling
- `Presentation/` - SwiftUI views and ViewModels
  - `OTPView` - Main entry point view that sets up the environment
  - `TripPlannerView` - Primary UI for trip planning
  - `ViewModel/TripPlannerViewModel` - Main state management (@MainActor)
  - `Map/` - Map-related views and state management
  - `Sheets/` - Bottom sheet UI components
  - `Common/` - Reusable UI components

### Key Integration Points

1. **Initialization**: Create `OTPConfiguration` with server URL and region, then instantiate `OTPView` with config and API service
2. **API Service**: Implement `APIService` protocol for custom networking or use provided `RestAPIService`
3. **Location Services**: `LocationManager.shared` handles location permissions and current location updates
4. **Theme Customization**: Configure appearance via `OTPThemeConfiguration` in the config

### Data Flow

1. User interactions in UI views trigger actions in `TripPlannerViewModel`
2. ViewModel calls `APIService` to fetch trip plans from OTP server
3. Response models (OTPResponse, Itinerary, etc.) are decoded and stored in ViewModel
4. UI updates reactively via SwiftUI property wrappers (@Published, @StateObject)

## Development Notes

- Minimum iOS version: 17.0
- Swift version: 5.9+
- The package uses SwiftUI and requires iOS platform features (not buildable for macOS due to iOS-specific APIs)
- Location permissions are handled automatically by LocationManager
- The demo app includes an onboarding flow for server configuration
- All models conform to `Codable` for JSON serialization
- Views use `@StateObject`, `@Published`, and `@EnvironmentObject` for reactive updates

## Testing

### Testing Framework
- **OTPKit Package Tests**: Uses XCTest with async/await patterns
- **Demo App Tests**: Uses Swift Testing framework (`@Test` attribute)
- **Test Helpers**: Located in `OTPKit/Tests/OTPKitTests/Helpers/`
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

// 1. Create configuration
let config = OTPConfiguration(
    serverURL: URL(string: "https://otp.example.com")!,
    region: MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
)

// 2. Initialize API service
let apiService = RestAPIService(configuration: config)

// 3. Create and present OTP view
let otpView = OTPView(configuration: config, apiService: apiService)
```

### Custom Theme Configuration
```swift
let themeConfig = OTPThemeConfiguration(
    primaryColor: .blue,
    secondaryColor: .green,
    backgroundColor: .systemBackground
)
config.themeConfiguration = themeConfig
```

### Implementing Custom API Service
```swift
class CustomAPIService: APIService {
    func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
        // Custom implementation
        // e.g., add authentication, caching, etc.
    }
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
- Uses `SheetPresenter` for bottom sheet management
- Sheets are defined in the `Sheet` enum
- Each sheet view is self-contained with its own state

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Ensure Xcode 15+ is installed
   - Check iOS deployment target is 17.0+
   - Clean build folder: `cmd+shift+k`

2. **Location Services Not Working**
   - Check Info.plist has required location usage descriptions
   - Verify simulator/device location services are enabled
   - Reset location permissions in Settings if needed

3. **API Connection Issues**
   - Verify OTP server URL is correct and accessible
   - Check if server supports CORS for web testing
   - Ensure server version matches API service (REST for 1.x)

4. **SwiftUI Preview Crashes**
   - Use `PreviewHelpers` for mock data
   - Ensure environment objects are provided in previews
   - Check for force unwrapped optionals

### Debug Tips
- Enable network debugging: `URLDataLoader` logs requests/responses
- Use `DebugDescriptionBuilder` for readable model output
- Check `OTPKitError` types for specific failure reasons

## Code Style & Conventions

### Swift Conventions
- Use Swift 5.9+ features (async/await, actors, etc.)
- Follow Swift API Design Guidelines
- Use meaningful variable names (avoid abbreviations)
- Prefer `let` over `var` when possible
- Use trailing closure syntax for single closure parameters

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

### Documentation
- Add doc comments for public APIs
- Include usage examples in comments
- Document complex algorithms
- Keep README up to date
