//
//  DirectionLegUnknownView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegUnknownView: View {
    let leg: Leg

    var body: some View {
        Image(systemName: "questionmark.circle")
            .font(.system(size: 24))
            .padding()
            .frame(width: 40)

        VStack(alignment: .leading, spacing: 4) {
            Text("To \(leg.to.name)")
                .font(.title3)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            Text(
                Formatters.formatDistance(Int(leg.distance)) +
                    ", about " +
                    Formatters.formatTimeDuration(leg.duration)
            )
            .foregroundStyle(.gray)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    DirectionLegUnknownView(leg: PreviewHelpers.buildLeg())
}
