//
//  DirectionLegVehicleView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegVehicleView: View {
    let leg: Leg

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Boarding section
                DirectionLegContainerView {
                    // Route number badge
                    Text(leg.route ?? "")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(backgroundColor)
                        .foregroundStyle(.white)
                        .font(.caption)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } rightContent: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(boardingText)
                            .font(.headline)

                        Text(leg.headsign ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            if let stopCode = leg.to.stopCode {
                                Text("Stop ID: \(stopCode)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("Scheduled at \(Formatters.formatDateToTime(leg.startTime))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, 4)

                // Alighting section
                DirectionLegContainerView {
                    // Empty space to align with the route badge
                    Color.clear
                } rightContent: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deboard at")
                            .font(.headline)

                        Text(leg.to.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            if let stopCode = leg.to.stopCode {
                                Text("Stop ID: \(stopCode)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("Arrives at \(Formatters.formatDateToTime(leg.endTime))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer()
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

    private var boardingText: String {
        let agency = leg.agencyName ?? ""
        let routeText = leg.route != nil && !leg.route!.isEmpty ? "Route \(leg.route!)" : ""
        return "Board \(agency) \(routeText)"
    }
}

#Preview {
    DirectionLegVehicleView(leg: PreviewHelpers.buildLeg())
}
