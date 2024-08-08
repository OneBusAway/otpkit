//
//  DirectionSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

public struct DirectionSheetView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared

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
        VStack(alignment: .leading, spacing: 24) {
            if let itinerary = locationManagerService.selectedItinerary {
                DireactionLegOriginDestinationView(title: "Origin", description: "Unknown Location")
                ForEach(itinerary.legs, id: \.self) { leg in
                    generateLegView(leg: leg)
                }
                DireactionLegOriginDestinationView(title: "Destination", description: "Unknown Location")
            }
        }
    }
}

#Preview {
    DirectionSheetView()
}
