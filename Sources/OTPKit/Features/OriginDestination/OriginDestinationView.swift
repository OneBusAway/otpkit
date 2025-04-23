//
//  OriginDestinationView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 05/07/24.
//

import MapKit
import SwiftUI

/// OriginDestinationView is the main view for setting up Origin/Destination in OTPKit.
/// It consists a list of Origin and Destination along with the MapKit
public struct OriginDestinationView: View {
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner

    // State variables for date/time selection
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var isDatePickerVisible = false
    @State private var isTimePickerVisible = false

    // Public Initializer
    public init() {}

    private func originDestinationField(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }

                Text(text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                Spacer()
            }
            .padding(7)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        })
        .foregroundStyle(.foreground)
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Origin Button
                originDestinationField(icon: "paperplane.fill", text: tripPlanner.originName) {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .origin
                }

                // Destination Button
                originDestinationField(icon: "mappin", text: tripPlanner.destinationName) {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .destination
                }

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
                .padding(.top, 8)

                // Get directions button
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
