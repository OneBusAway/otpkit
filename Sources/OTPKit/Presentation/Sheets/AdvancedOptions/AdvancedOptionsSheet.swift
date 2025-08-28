//
//  AdvancedOptionsSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-08-17.
//

import SwiftUI
import MapKit

/// A bottom sheet that presents advanced options for trip planning
struct AdvancedOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.otpTheme) private var theme
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel

    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                departureTimeSection
                accessibilitySection
                routeOptimizationSection
                walkingDistanceSection
            }
            .navigationTitle(
                Localization.string("bottom.advanced_options", comment: "Shows Adavanced Options title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
        }
        .onAppear(perform: syncWithViewModel)
    }
}

// MARK: - View Components

private extension AdvancedOptionsSheet {

    var departureTimeSection: some View {
        Section(OTPLoc("advanced_options.departure_time_title", comment: "Departure time section title")) {
            ForEach(TimePreference.allCases, id: \.self) { preference in
                OptionRowView(
                    iconName: preference.iconName,
                    title: preference.title,
                    description: preference.description,
                    isSelected: tripPlannerVM.timePreference == preference
                ) {
                    tripPlannerVM.timePreference = preference
                }
            }

            if tripPlannerVM.timePreference.requiresTimeSelection {
                TimeSelectionView(
                    selectedDate: $selectedDate,
                    selectedTime: $selectedTime
                )
            }
        }
    }

    var accessibilitySection: some View {
        Section {
            HStack {
                Image(systemName: "figure.roll")
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24)

                Text(OTPLoc("advanced_options.wheelchair_accessible", comment: "Wheelchair accessible toggle label"))

                Spacer()

                Toggle("", isOn: $tripPlannerVM.isWheelchairAccessible)
                    .labelsHidden()
                    .tint(theme.primaryColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(OTPLoc("advanced_options.wheelchair_accessible_label", comment: "Accessibility label for wheelchair toggle"))
            .accessibilityHint(OTPLoc("advanced_options.wheelchair_toggle_hint", comment: "Accessibility hint for wheelchair toggle"))
        } footer: {
            Text(OTPLoc("advanced_options.wheelchair_footer", comment: "Footer text explaining wheelchair accessibility"))
        }
    }

    var routeOptimizationSection: some View {
        Section(OTPLoc("advanced_options.route_optimization_title", comment: "Route optimization section title")) {
            ForEach(RoutePreference.allCases, id: \.self) { preference in
                OptionRowView(
                    iconName: preference.iconName,
                    title: preference.title,
                    description: preference.description,
                    isSelected: tripPlannerVM.routePreference == preference
                ) {
                    tripPlannerVM.routePreference = preference
                }
            }
        }
    }

    var walkingDistanceSection: some View {
        Section(OTPLoc("advanced_options.walking_distance_title", comment: "Walking distance section title")) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24)

                Picker(OTPLoc("advanced_options.max_walking_distance", comment: "Maximum walking distance picker label"), selection: $tripPlannerVM.maxWalkingDistance) {
                    ForEach(WalkingDistance.allCases, id: \.self) { distance in
                        Text(distance.title).tag(distance)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.primaryColor)
                .accessibilityLabel(OTPLoc("advanced_options.max_walking_distance", comment: "Maximum walking distance accessibility label"))
                .accessibilityValue(tripPlannerVM.maxWalkingDistance.title)
            }
        }
    }

    var cancelButton: some View {
        Button(OTPLoc("advanced_options.cancel", comment: "Cancel button text")) {
            dismiss()
        }
        .foregroundColor(theme.secondaryColor)
        .accessibilityLabel(OTPLoc("advanced_options.cancel_accessibility", comment: "Cancel button accessibility label"))
    }

    var doneButton: some View {
        Button(OTPLoc("advanced_options.done", comment: "Done button text")) {
            saveAdvancedOptions()
            dismiss()
        }
        .fontWeight(.semibold)
        .foregroundColor(theme.primaryColor)
        .accessibilityLabel(OTPLoc("advanced_options.save_accessibility", comment: "Done button accessibility label"))
    }
}

// MARK: - Private Methods

private extension AdvancedOptionsSheet {

    func syncWithViewModel() {
        if let departureDate = tripPlannerVM.departureDate {
            selectedDate = departureDate
        }
        if let departureTime = tripPlannerVM.departureTime {
            selectedTime = departureTime
        }
    }

    func saveAdvancedOptions() {
        switch tripPlannerVM.timePreference {
        case .leaveNow:
            tripPlannerVM.departureDate = Date()
            tripPlannerVM.departureTime = Date()
        case .departAt, .arriveBy:
            tripPlannerVM.departureDate = selectedDate
            tripPlannerVM.departureTime = selectedTime
        }
    }
}

#Preview {
    AdvancedOptionsSheet()
        .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
}
