//
//  DirectionLegBikeView.swift
//  OTPKit
//

import SwiftUI

/// A bicycle leg in the legacy directions list — personal bike or rental ride.
struct DirectionLegBikeView: View {
    let leg: Leg

    var body: some View {
        DirectionLegContainerView {
            Image(systemName: "bicycle")
                .font(.system(size: 24))
                .foregroundStyle(leg.isRentalRide ? Color.otpRentalPurple : Color.primary)
        } rightContent: {
            VStack(alignment: .leading, spacing: 4) {
                Text(instruction)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)

                Text(OTPLoc(
                    "leg.walk_distance_duration",
                    comment: "Walking distance followed by approximate duration",
                    Formatters.formatDistance(Int(leg.distance)),
                    Formatters.formatTimeDuration(leg.duration)
                ))
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var instruction: String {
        if leg.isRentalRide {
            return OTPLoc("leg.ride_rental_bike_to",
                          comment: "Instruction to ride a rental bike to a place",
                          leg.riderFacingToName)
        }
        return OTPLoc("leg.bike_to", comment: "Instruction to bike to a place", leg.riderFacingToName)
    }
}

#Preview {
    DirectionLegBikeView(leg: PreviewHelpers.buildLeg())
}
