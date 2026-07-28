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
                            // The boarding stop, not `leg.to` — that is where the rider gets off,
                            // and it is shown in the alighting section below.
                            if let stopCode = leg.from.stopCode {
                                Text(OTPLoc("leg.stop_id", comment: "Transit stop identifier", stopCode))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(OTPLoc("leg.scheduled_at", comment: "Scheduled departure time for a transit leg",
                                        Formatters.formatDateToTime(leg.startTime)))
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
                        Text(OTPLoc("leg.deboard_at", comment: "Label for where the rider exits the vehicle"))
                            .font(.headline)

                        Text(leg.to.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            if let stopCode = leg.to.stopCode {
                                Text(OTPLoc("leg.stop_id", comment: "Transit stop identifier", stopCode))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(OTPLoc("leg.arrives_at", comment: "Arrival time for a transit leg",
                                        Formatters.formatDateToTime(leg.endTime)))
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
        guard let route = leg.route, !route.isEmpty else {
            return OTPLoc("leg.board_agency_only", comment: "Board a vehicle when no route is known: agency", agency)
        }
        return OTPLoc("leg.board_with_route",
                      comment: "Board a vehicle: agency name, then route identifier",
                      agency, route)
    }
}

#Preview {
    DirectionLegVehicleView(leg: PreviewHelpers.buildLeg())
}
