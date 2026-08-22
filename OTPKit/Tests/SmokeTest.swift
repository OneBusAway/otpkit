//
//  SmokeTest.swift
//  OTPKitTests
//
//  Basic smoke test to verify test infrastructure
//

import Testing
@testable import OTPKit

@Test("Smoke test - verify test infrastructure works")
func smokeTest() {
    #expect(true)
}

@Test("TestFixtures - can create OTPConfiguration")
func testFixturesCreateConfiguration() {
    let config = TestFixtures.makeOTPConfiguration()
    #expect(config.otpServerURL.absoluteString == "https://otp.example.com")
}

@Test("TestFixtures - can create Place")
func testFixturesCreatePlace() {
    let place = TestFixtures.makePlace(name: "Test")
    #expect(place.name == "Test")
    #expect(place.lat == 47.0)
    #expect(place.lon == -122.0)
}

// `MockMapProvider` conforms to `OTPMapProvider`, which is `@MainActor`, so the
// mock picks up that isolation and the test has to run there too.
@MainActor
@Test("MockMapProvider - tracks addRoute calls")
func mockMapProviderTracksRouteCalls() {
    let mockMap = MockMapProvider()
    #expect(mockMap.addRouteCalls.isEmpty)

    mockMap.addRoute(
        coordinates: [],
        color: .blue,
        lineWidth: 3.0,
        identifier: "test-route",
        lineDashPattern: nil
    )

    #expect(mockMap.addRouteCalls.count == 1)
    #expect(mockMap.addRouteCalls[0].identifier == "test-route")
}
