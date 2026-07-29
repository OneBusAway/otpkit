//
//  ItineraryLegBikeView.swift
//  OTPKit
//

import SwiftUI

/// Represents an itinerary leg ridden on a bicycle — personal or rental.
/// Rental rides tint in rental purple so they read as part of the rental system.
struct ItineraryLegBikeView: View {
    let leg: Leg

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bicycle")
                .font(.caption)
            Text(Formatters.formatTimeDuration(leg.duration))
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(leg.isRentalRide ? Color.otpRentalPurple.opacity(0.15) : Color.gray.opacity(0.2))
        .foregroundStyle(leg.isRentalRide ? Color.otpRentalPurple : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(height: 40)
    }
}

#Preview {
    ItineraryLegBikeView(leg: PreviewHelpers.buildLeg())
}
