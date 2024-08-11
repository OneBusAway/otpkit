//
//  OriginDestinationView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 05/07/24.
//

import MapKit
import SwiftUI

/// OriginDestinationView is the main view for setting up Origin/Destination in OTPKit.
/// It consists a list of Origin and Destination along with the `MapKit`
public struct OriginDestinationView: View {
    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment
    @EnvironmentObject private var tripPlanner: TripPlannerService
    @State private var isSheetOpened = false

    // Public Initializer
    public init() {}

    public var body: some View {
        VStack {
            List {
                Button(action: {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .origin
                }, label: {
                    HStack(spacing: 16) {
                        Image(systemName: "paperplane.fill")
                            .background(
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 30, height: 30)
                            )
                        Text(tripPlanner.originName)
                    }
                })
                .foregroundStyle(.foreground)

                Button(action: {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .destination
                }, label: {
                    HStack(spacing: 16) {
                        Image(systemName: "mappin")
                            .background(
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 30, height: 30)
                            )
                        Text(tripPlanner.destinationName)
                    }
                })
                .foregroundStyle(.foreground)
            }
            .frame(height: 135)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    OriginDestinationView()
        .environmentObject(PreviewHelpers.buildTripPlannerService())
}
