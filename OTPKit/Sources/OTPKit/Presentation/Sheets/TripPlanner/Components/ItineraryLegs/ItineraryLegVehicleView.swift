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

    @Environment(\.otpTheme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            Text(leg.route ?? "?")
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
        switch leg.routeType {
        case .nonTransit: return "figure.walk"
        case .tram: return "tram.fill"
        case .subway: return "lightrail.fill"
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        case .ferry: return "ferry.fill"
        case .cableCar: return "cablecar.fill"
        case .gondola: fallthrough
        case .funicular: fallthrough
        default: return ""
        }
    }

    private var backgroundColor: Color {
        if leg.mode == "TRAM" {
            Color.green
        } else if leg.mode == "BUS" {
            theme.primaryColor
        } else {
            Color.pink
        }
    }
}

#Preview {
    ItineraryLegVehicleView(leg: PreviewHelpers.buildLeg(route: "545"))
}
