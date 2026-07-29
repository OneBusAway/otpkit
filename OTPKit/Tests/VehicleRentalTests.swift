//
//  VehicleRentalTests.swift
//  OTPKitTests
//
//  Tests for vehicle rental models: union decoding, form factors, and display labels.
//

import Foundation
import Testing
@testable import OTPKit

@Suite("Vehicle Rental Models")
struct VehicleRentalTests {

    // MARK: - VehicleFormFactor

    @Suite("VehicleFormFactor")
    struct FormFactorTests {

        @Test("Decodes every OTP FormFactor value")
        func decodesKnownValues() throws {
            for factor in VehicleFormFactor.allCases {
                let decoded = try JSONDecoder().decode(
                    VehicleFormFactor.self,
                    from: Data("\"\(factor.rawValue)\"".utf8)
                )
                #expect(decoded == factor)
            }
        }

        @Test("Unknown wire values decode fail-open as .other")
        func unknownValueDecodesAsOther() throws {
            let decoded = try JSONDecoder().decode(
                VehicleFormFactor.self,
                from: Data("\"HOVERBOARD\"".utf8)
            )
            #expect(decoded == .other)
        }

        @Test("Scooter and bicycle groupings cover their variants")
        func groupings() {
            #expect(VehicleFormFactor.scooter.isScooter)
            #expect(VehicleFormFactor.scooterSeated.isScooter)
            #expect(VehicleFormFactor.scooterStanding.isScooter)
            #expect(!VehicleFormFactor.bicycle.isScooter)

            #expect(VehicleFormFactor.bicycle.isBicycle)
            #expect(VehicleFormFactor.cargoBicycle.isBicycle)
            #expect(!VehicleFormFactor.scooter.isBicycle)
            #expect(!VehicleFormFactor.other.isBicycle)
        }
    }

    // MARK: - RentalNetwork

    @Suite("RentalNetwork")
    struct NetworkTests {

        @Test("Network id humanizes to an operator name")
        func displayName() {
            #expect(RentalNetwork(networkId: "lime_seattle", url: nil).displayName == "Lime")
            #expect(RentalNetwork(networkId: "bird-seattle-washington", url: nil).displayName == "Bird")
            #expect(RentalNetwork(networkId: "pronto", url: nil).displayName == "Pronto")
        }
    }

    // MARK: - Display Labels

    @Suite("displayLabel")
    struct DisplayLabelTests {

        @Test("Vehicle label prefers operator + type over the raw name")
        func vehicleWithNetwork() {
            let rental = VehicleRental.vehicle(makeVehicle(
                name: "Default vehicle type",
                networkId: "lime_seattle",
                formFactor: .bicycle,
                propulsionType: "ELECTRIC_ASSIST"
            ))
            #expect(rental.displayLabel == "Lime e-bike")
        }

        @Test("Scooter label uses the scooter type name")
        func scooterLabel() {
            let rental = VehicleRental.vehicle(makeVehicle(
                name: "Default vehicle type",
                networkId: "lime_seattle",
                formFactor: .scooterStanding,
                propulsionType: "ELECTRIC"
            ))
            #expect(rental.displayLabel == "Lime scooter")
        }

        @Test("Placeholder name is never surfaced, even without a network")
        func placeholderSuppressed() {
            let rental = VehicleRental.vehicle(makeVehicle(
                name: "Default vehicle type",
                networkId: nil,
                formFactor: .bicycle,
                propulsionType: "ELECTRIC_ASSIST"
            ))
            #expect(rental.displayLabel == "E-bike")
        }

        @Test("A real feed name is used when no network is available")
        func realNameUsed() {
            let rental = VehicleRental.vehicle(makeVehicle(
                name: "Blue Cruiser 42",
                networkId: nil,
                formFactor: .bicycle,
                propulsionType: "HUMAN"
            ))
            #expect(rental.displayLabel == "Blue Cruiser 42")
        }

        @Test("Station label is the station name")
        func stationLabel() {
            let station = VehicleRentalStation(
                stationId: "pronto:BT-01",
                name: "Pine St & 9th Ave",
                lat: 47.61,
                lon: -122.33,
                vehiclesAvailable: 3,
                spacesAvailable: 15,
                allowPickupNow: true,
                allowDropoffNow: true,
                operative: true,
                rentalNetwork: nil,
                rentalUris: nil,
                availableVehicles: nil,
                availableSpaces: nil
            )
            #expect(VehicleRental.station(station).displayLabel == "Pine St & 9th Ave")
        }
    }

    // MARK: - Union Decoding

    @Suite("Union decoding")
    struct UnionDecodingTests {

        @Test("Convenience accessors delegate to the wrapped value")
        func convenienceAccessors() throws {
            let json = """
            {
              "__typename": "RentalVehicle",
              "vehicleId": "lime_seattle:abc",
              "name": "Default vehicle type",
              "lat": 47.61,
              "lon": -122.33,
              "allowPickupNow": true,
              "operative": null,
              "rentalNetwork": {"networkId": "lime_seattle", "url": null},
              "rentalUris": null,
              "vehicleType": {"formFactor": "BICYCLE", "propulsionType": "ELECTRIC_ASSIST"},
              "fuel": {"percent": null, "range": 20000}
            }
            """
            let rental = try JSONDecoder().decode(VehicleRental.self, from: Data(json.utf8))

            #expect(rental.id == "lime_seattle:abc")
            #expect(rental.coordinate.latitude == 47.61)
            #expect(rental.isOperative)
            #expect(rental.batteryPercent == nil)
            #expect(rental.rentalUris == nil)
            #expect(rental.rentalNetwork?.displayName == "Lime")
        }

        @Test("Unknown __typename throws a DecodingError")
        func unknownTypenameThrows() {
            let json = """
            {"__typename": "RentalDrone", "droneId": "x"}
            """
            #expect(throws: DecodingError.self) {
                _ = try JSONDecoder().decode(VehicleRental.self, from: Data(json.utf8))
            }
        }
    }

    // MARK: - Helpers

    private static func makeVehicle(
        name: String,
        networkId: String?,
        formFactor: VehicleFormFactor?,
        propulsionType: String?
    ) -> RentalVehicle {
        RentalVehicle(
            vehicleId: "test:1",
            name: name,
            lat: 47.61,
            lon: -122.33,
            allowPickupNow: true,
            operative: true,
            rentalNetwork: networkId.map { RentalNetwork(networkId: $0, url: nil) },
            rentalUris: nil,
            vehicleType: formFactor.map { VehicleType(formFactor: $0, propulsionType: propulsionType) },
            fuel: nil
        )
    }
}
