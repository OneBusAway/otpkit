//
//  DirectionLegWalkView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegWalkView: View {
    let leg: Leg

    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .padding()
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text("Walk to \(leg.to.name)")
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(Formatters.formatDistance(Int(leg.distance))), about \(Formatters.formatTimeDuration(leg.duration))")
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    DirectionLegWalkView(leg: PreviewHelpers.buildLeg())
}
