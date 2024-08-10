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
                .font(.system(size: 24))
                .padding()
                .frame(width: 40)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("Walk to \(leg.to.name)")
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

                Rectangle()
                    .fill(.foreground)
                    .frame(height: 1)
                    .padding(.top, 16)
            }
        }
    }
}

#Preview {
    DirectionLegWalkView(leg: PreviewHelpers.buildLeg())
}