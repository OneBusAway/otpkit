//
//  ItineraryDetailsView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/26/25.
//

import SwiftUI
import CoreLocation

struct ItineraryDetailsView: View {
    let origin: Location?
    let destination: Location?
    let itinerary: Itinerary
    let handleTap: ((CLLocationCoordinate2D, String) -> Void)? = nil

    @Environment(\.dismiss) var dismiss

    public var body: some View {
        List {
            Section {
                PageHeaderView(
                    text: destination?.title ?? "Destination"
                ) {
                    dismiss()
                }
            }
            .listRowBackground(Color.clear)

            Section {
                createOriginView(itinerary: itinerary)
                createLegsView(itinerary: itinerary)
                createDestinationView(itinerary: itinerary)
            }
            .listRowBackground(Color.clear)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .listStyle(PlainListStyle())
    }

    private func generateLegView(leg: Leg) -> some View {
        Group {
            switch leg.mode {
            case "BUS", "TRAM":
                DirectionLegVehicleView(leg: leg)
            case "WALK":
                DirectionLegWalkView(leg: leg)
            default:
                DirectionLegUnknownView(leg: leg)
            }
        }
    }

    private func createOriginView(itinerary _: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Start",
            description: origin?.title ?? "Unknown"
        )
        .id("item-0")
        .onTapGesture {
            if let originCoordinate = origin?.coordinate {
                handleTap?(originCoordinate, "item-0")
            }
        }
    }

    private func createLegsView(itinerary: Itinerary) -> some View {
        ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
            generateLegView(leg: leg)
                .id("item-\(index + 1)")
                .onTapGesture {
                    let coordinate = CLLocationCoordinate2D(latitude: leg.to.lat, longitude: leg.to.lon)
                    handleTap?(coordinate, "item-\(index + 1)")
                }
        }
    }

    private func createDestinationView(itinerary: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Destination",
            description: destination?.title ?? "Unknown"
        )
        .id("item-\(itinerary.legs.count + 1)")
        .onTapGesture {
            if let destinationCoordinate = destination?.coordinate {
                handleTap?(destinationCoordinate, "item-\(itinerary.legs.count + 1)")
            }
        }
    }
}
