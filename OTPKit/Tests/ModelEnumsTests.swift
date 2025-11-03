//
//  ModelEnumsTests.swift
//  OTPKitTests
//
//  Tests for model enums: WalkingDistance, TimePreference, RoutePreference
//

import Testing
@testable import OTPKit

@Suite("Model Enums Tests")
struct ModelEnumsTests {

    // MARK: - WalkingDistance Tests

    @Suite("WalkingDistance")
    struct WalkingDistanceTests {

        @Test("All cases are present")
        func allCases() {
            let cases = WalkingDistance.allCases
            #expect(cases.count == 4)
            #expect(cases.contains(.quarterMile))
            #expect(cases.contains(.halfMile))
            #expect(cases.contains(.oneMile))
            #expect(cases.contains(.twoMiles))
        }

        @Test("Quarter mile title")
        func quarterMileTitle() {
            #expect(WalkingDistance.quarterMile.title == "0.25 mile")
        }

        @Test("Half mile title")
        func halfMileTitle() {
            #expect(WalkingDistance.halfMile.title == "0.5 mile")
        }

        @Test("One mile title")
        func oneMileTitle() {
            #expect(WalkingDistance.oneMile.title == "1 mile")
        }

        @Test("Two miles title")
        func twoMilesTitle() {
            #expect(WalkingDistance.twoMiles.title == "2 miles")
        }

        @Test("Quarter mile meters")
        func quarterMileMeters() {
            #expect(WalkingDistance.quarterMile.meters == 402)
        }

        @Test("Half mile meters")
        func halfMileMeters() {
            #expect(WalkingDistance.halfMile.meters == 805)
        }

        @Test("One mile meters")
        func oneMileMeters() {
            #expect(WalkingDistance.oneMile.meters == 1609)
        }

        @Test("Two miles meters")
        func twoMilesMeters() {
            #expect(WalkingDistance.twoMiles.meters == 3219)
        }

        @Test("Accessibility description quarter mile")
        func quarterMileAccessibility() {
            let description = WalkingDistance.quarterMile.accessibilityDescription
            #expect(description == "Maximum walking distance: 0.25 mile")
        }

        @Test("Accessibility description includes title")
        func accessibilityDescriptionIncludesTitle() {
            for distance in WalkingDistance.allCases {
                let description = distance.accessibilityDescription
                #expect(description.contains(distance.title))
                #expect(description.contains("Maximum walking distance"))
            }
        }
    }

    // MARK: - TimePreference Tests

    @Suite("TimePreference")
    struct TimePreferenceTests {

        @Test("All cases are present")
        func allCases() {
            let cases = TimePreference.allCases
            #expect(cases.count == 3)
            #expect(cases.contains(.leaveNow))
            #expect(cases.contains(.departAt))
            #expect(cases.contains(.arriveBy))
        }

        @Test("Raw values")
        func rawValues() {
            #expect(TimePreference.leaveNow.rawValue == "now")
            #expect(TimePreference.departAt.rawValue == "depart")
            #expect(TimePreference.arriveBy.rawValue == "arrive")
        }

        @Test("Leave now does not require time selection")
        func leaveNowTimeSelection() {
            #expect(!TimePreference.leaveNow.requiresTimeSelection)
        }

        @Test("Depart at requires time selection")
        func departAtTimeSelection() {
            #expect(TimePreference.departAt.requiresTimeSelection)
        }

        @Test("Arrive by requires time selection")
        func arriveByTimeSelection() {
            #expect(TimePreference.arriveBy.requiresTimeSelection)
        }

        @Test("Icon names are not empty")
        func iconNamesNotEmpty() {
            for preference in TimePreference.allCases {
                #expect(!preference.iconName.isEmpty)
            }
        }

        @Test("Leave now icon name")
        func leaveNowIcon() {
            #expect(TimePreference.leaveNow.iconName == "clock")
        }

        @Test("Depart at icon name")
        func departAtIcon() {
            #expect(TimePreference.departAt.iconName == "clock.arrow.2.circlepath")
        }

        @Test("Arrive by icon name")
        func arriveByIcon() {
            #expect(TimePreference.arriveBy.iconName == "clock.badge.checkmark")
        }

        @Test("Titles are not empty")
        func titlesNotEmpty() {
            for preference in TimePreference.allCases {
                #expect(!preference.title.isEmpty)
            }
        }

        @Test("Descriptions are not empty")
        func descriptionsNotEmpty() {
            for preference in TimePreference.allCases {
                #expect(!preference.description.isEmpty)
            }
        }

        @Test("Accessibility description includes title and description")
        func accessibilityDescription() {
            for preference in TimePreference.allCases {
                let accessibility = preference.accessibilityDescription
                #expect(!accessibility.isEmpty)
                // Should include both title and description
                #expect(accessibility.contains(":"))
            }
        }
    }

    // MARK: - RoutePreference Tests

    @Suite("RoutePreference")
    struct RoutePreferenceTests {

        @Test("All cases are present")
        func allCases() {
            let cases = RoutePreference.allCases
            #expect(cases.count == 2)
            #expect(cases.contains(.fastestTrip))
            #expect(cases.contains(.fewestTransfers))
        }

        @Test("Raw values")
        func rawValues() {
            #expect(RoutePreference.fastestTrip.rawValue == "fastest")
            #expect(RoutePreference.fewestTransfers.rawValue == "transfers")
        }

        @Test("Fastest trip icon name")
        func fastestTripIcon() {
            #expect(RoutePreference.fastestTrip.iconName == "timer")
        }

        @Test("Fewest transfers icon name")
        func fewestTransfersIcon() {
            #expect(RoutePreference.fewestTransfers.iconName == "arrow.triangle.swap")
        }

        @Test("Titles are not empty")
        func titlesNotEmpty() {
            for preference in RoutePreference.allCases {
                #expect(!preference.title.isEmpty)
            }
        }

        @Test("Descriptions are not empty")
        func descriptionsNotEmpty() {
            for preference in RoutePreference.allCases {
                #expect(!preference.description.isEmpty)
            }
        }

        @Test("Icon names are not empty")
        func iconNamesNotEmpty() {
            for preference in RoutePreference.allCases {
                #expect(!preference.iconName.isEmpty)
            }
        }

        @Test("Accessibility description includes title and description")
        func accessibilityDescription() {
            for preference in RoutePreference.allCases {
                let accessibility = preference.accessibilityDescription
                #expect(!accessibility.isEmpty)
                // Should include both title and description
                #expect(accessibility.contains(":"))
            }
        }
    }
}
