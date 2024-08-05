//
//  ItineraryLegVehicleView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import SwiftUI

/// Represents an itinerary leg that uses a vehicular method of conveyance.
struct ItineraryLegVehicleView: View {
    let leg: Leg

    var body: some View {
        HStack(spacing: 4) {
            Text(leg.route ?? "")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .foregroundStyle(.foreground)
                .font(.caption)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Image(systemName: imageName)
                .foregroundStyle(.foreground)
        }.frame(height: 40)
    }

    private var imageName: String {
        if leg.mode == "TRAM" {
            return "tram"
        } else if leg.mode == "BUS" {
            return "bus"
        } else {
            return ""
        }
    }

    private var backgroundColor: Color {
        if leg.mode == "TRAM" {
            return Color.blue
        } else if leg.mode == "BUS" {
            return Color.green
        } else {
            return Color.pink
        }
    }

}

#Preview {
    ItineraryLegVehicleView(leg: PreviewHelpers.buildLeg())
}
