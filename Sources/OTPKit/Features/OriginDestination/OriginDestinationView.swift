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
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner
    @State private var isSheetOpened = false

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var isDatePickerVisible = false
    @State private var isTimePickerVisible = false

    // Public Initializer
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Origin Button
                Button(action: {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .origin
                }, label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 32, height: 32)

                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                        }

                        Text(tripPlanner.originName)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(7)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                })
                .foregroundStyle(.primary)

                Divider()

                // Destination Button
                Button(action: {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .destination
                }, label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 32, height: 32)

                            Image(systemName: "mappin")
                                .foregroundColor(.white)
                        }

                        Text(tripPlanner.destinationName)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(7)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                })
                .foregroundStyle(.primary)

                // Date/Time Selector
                DateTimeSelector(
                    selectedDate: $selectedDate,
                    selectedTime: $selectedTime,
                    isDatePickerVisible: $isDatePickerVisible,
                    isTimePickerVisible: $isTimePickerVisible
                )
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                // get directions button
                getDirectionsButtonView()

            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background()
    }

    // MARK: DirectionsButton
    private func getDirectionsButtonView() -> some View {
        if let origin = tripPlanner.originCoordinate, let destination = tripPlanner.destinationCoordinate {
            return AnyView(
                GetDirectionsButton(
                    originName: tripPlanner.originName,
                    destinationName: tripPlanner.destinationName
                ) {
                    tripPlanner.fetchTrip()
                }
                    .padding(.top, 12)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

#Preview {
    OriginDestinationView()
}
