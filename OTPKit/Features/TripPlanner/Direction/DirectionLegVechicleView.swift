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
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("Board to \(leg.agencyName ?? "")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(leg.headsign ?? "")")
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Scheduled at \(Formatters.formatDateToTime(leg.startTime))")
                    .fixedSize(horizontal: false, vertical: true)

                if let polyline = leg.decodePolyline() {
                    let coordinatesString = polyline.map { point in
                        String(format: "%.6f, %.6f", point.latitude, point.longitude)
                    }.joined(separator: "\n")

                    Text(coordinatesString)
                }

                Rectangle()
                    .fill(.foreground)
                    .frame(height: 1)
                    .padding(.top, 16)
            }
        }
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
