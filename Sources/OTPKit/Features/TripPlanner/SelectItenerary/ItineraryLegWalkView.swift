//
//  ItineraryLegWalkView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import SwiftUI

/// Represents an itinerary leg that uses a walking method of conveyance.
struct ItineraryLegWalkView: View {
    let leg: Leg

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
            Text(Formatters.formatTimeDuration(leg.duration))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .foregroundStyle(.gray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(height: 40)
    }
}

#Preview {
    ItineraryLegWalkView(leg: PreviewHelpers.buildLeg())
}
