//
//  ItineraryLegViewTests.swift
//  OTPKit
//
//  Created by Shreyas Sahoo on 31/03/25.
//

import XCTest
import ViewInspector
import SwiftUI
@testable import OTPKit

class ItineraryLegViewTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUp() {
        super.setUp()
    }
    
    // MARK: - Unknown Leg Tests
    
    func testItineraryLegUnknownView() throws {
        // Given
        let leg = PreviewHelpers.buildLeg()
        let view = ItineraryLegUnknownView(leg: leg)
        
        // When
        let hStack = try view.inspect().implicitAnyView().hStack()
        
        // Then
        let text = try hStack.text(0)
        let expectedText = "\(leg.mode): \(Formatters.formatTimeDuration(leg.duration))"
        XCTAssertEqual(try text.string(), expectedText)
    }
    
    // MARK: - Vehicle Leg Tests
    
    func testItineraryLegVehicleView() throws {
        // Given
        let routeNumber = "43"
        let transportMode = "BUS"
        let leg = createTestLeg(mode: transportMode, route: routeNumber)
        let view = ItineraryLegVehicleView(leg: leg)
        
        // When
        let hStack = try view.inspect().implicitAnyView().hStack()
        
        // Then
        let routeText = try hStack.text(0).string()
        XCTAssertEqual(routeText, routeNumber)
        XCTAssertNoThrow(try hStack.image(1))
    }
    
    // MARK: - Walk Leg Tests
    
    func testItineraryLegWalkView() throws {
        // Given
        let leg = createTestLeg(mode: "WALK", route: nil)
        let view = ItineraryLegWalkView(leg: leg)
        
        // When
        let hStack = try view.inspect().implicitAnyView().hStack()
        
        // Then
        XCTAssertNoThrow(try hStack.image(0))
        let durationText = try hStack.text(1)
        XCTAssertEqual(try durationText.string(), Formatters.formatTimeDuration(leg.duration))
    }
    
    // MARK: - Helpers
    
    private func createTestLeg(mode: String, route: String?) -> Leg {
        return Leg(
            startTime: Date(),
            endTime: Date(),
            mode: mode,
            route: route,
            agencyName: "Test Agency",
            from: Place(name: "Start Location", lon: 47, lat: -122, vertexType: ""),
            to: Place(name: "End Location", lon: 47, lat: -122, vertexType: ""),
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 100,
            transitLeg: mode != "WALK",
            duration: 10,
            realTime: true,
            streetNames: nil,
            pathway: nil,
            steps: nil,
            headsign: nil
        )
    }
}
