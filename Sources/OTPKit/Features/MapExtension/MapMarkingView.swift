//
//  MapMarkingView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 18/07/24.
//

import SwiftUI


/// View for Map Marking Mode
/// User able to add Marking directly from the map
public struct MapMarkingView: View {
    @EnvironmentObject private var tripPlanner: TripPlannerService

    public init() {}
    public var body: some View {
        VStack {
            Spacer()

            Text("Tap on the map to add a pin.")
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(16)

            HStack(spacing: 16) {
                Button {
                    tripPlanner.toggleMapMarkingMode(false)
                    tripPlanner.selectAndRefreshCoordinate()
                    tripPlanner.removeOriginDestinationData()
                } label: {
                    Text("Cancel")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    tripPlanner.toggleMapMarkingMode(false)
                    tripPlanner.addOriginDestinationData()
                    tripPlanner.selectAndRefreshCoordinate()
                } label: {
                    Text("Add Pin")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .padding(.bottom, 24)
    }
}

#Preview {
    MapMarkingView()
        .environmentObject(PreviewHelpers.buildTripPlannerService())
}
