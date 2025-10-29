//
//  ItineraryLegVehicleView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import SwiftUI
import OSLog

/// Represents an itinerary leg that uses a vehicular method of conveyance.
struct ItineraryLegVehicleView: View {
    let leg: Leg

    @Environment(\.otpTheme) private var theme

    var body: some View {
        HStack(spacing: 2) {
            Text(leg.route ?? "?")
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(backgroundColor)
                .foregroundStyle(textColor)
                .font(.footnote)
                .fontWeight(.semibold)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Image(systemName: imageName)
                .foregroundStyle(.secondary)
        }.frame(minHeight: 40)
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
        case .gondola: return ""
        case .funicular: return ""
        default: return ""
        }
    }

    private var textColor: Color {
        if let color = leg.routeTextUIColor {
            Logger.main.debug("Using color \(String(describing: leg.routeTextColor)) for text")
            return color
        }

        return .white
    }

    private var backgroundColor: Color {
        if let color = leg.routeUIColor {
            return color
        }

        return Color(.systemFill)
    }
}

#Preview {
    ItineraryLegVehicleView(leg: PreviewHelpers.buildLeg(route: "545"))
}
