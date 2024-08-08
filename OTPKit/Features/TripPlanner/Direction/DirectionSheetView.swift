//
//  DirectionSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

public struct DirectionSheetView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared

    @Environment(\.dismiss) var dismiss

    public init() {}

    private func generateLegView(leg: Leg) -> some View {
        Group {
            switch leg.mode {
            case "BUS", "TRAM":
                DirectionLegVechicleView(leg: leg)
            case "WALK":
                DirectionLegWalkView(leg: leg)
            default:
                DirectionLegUnknownView(leg: leg)
            }
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeaderView(text: "\(locationManagerService.destinationName)") {
                    locationManagerService.resetTripPlanner()
                    dismiss()
                }

                if let itinerary = locationManagerService.selectedItinerary {
                    DireactionLegOriginDestinationView(
                        title: "Origin",
                        description: locationManagerService.originName
                    )
                    ForEach(itinerary.legs, id: \.self) { leg in
                        generateLegView(leg: leg)
                    }
                    DireactionLegOriginDestinationView(
                        title: "Destination",
                        description: locationManagerService.destinationName
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
        }
    }
}

#Preview {
    DirectionSheetView()
}
