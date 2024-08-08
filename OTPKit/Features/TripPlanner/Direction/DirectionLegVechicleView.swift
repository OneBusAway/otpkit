//
//  DirectionLegVechicleView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegVechicleView: View {
    let leg: Leg

    var body: some View {
        HStack(spacing: 24) {
            Text(leg.route ?? "")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .foregroundStyle(.foreground)
                .font(.caption)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Board to \(leg.agencyName ?? "")")
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(leg.headsign ?? "")")
                    .fixedSize(horizontal: false, vertical: true)
                Text("Scheduled at \(Formatters.formatBusSchedule(leg.startTime))")
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.frame(height: 40)
    }

    private var backgroundColor: Color {
        if leg.mode == "TRAM" {
            Color.blue
        } else if leg.mode == "BUS" {
            Color.green
        } else {
            Color.pink
        }
    }
}

#Preview {
    DirectionLegVechicleView(leg: PreviewHelpers.buildLeg())
}
