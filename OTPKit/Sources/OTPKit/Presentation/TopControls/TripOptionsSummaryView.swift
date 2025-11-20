//
//  TripOptionsSummaryView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 11/19/25.
//

import SwiftUI

/// Displays a horizontal row of pill-shaped buttons showing selected trip options
/// that differ from defaults, similar to Apple Maps.
struct TripOptionsSummaryView: View {
    @EnvironmentObject var tripPlannerVM: TripPlannerViewModel

    /// Action to perform when an option pill is tapped
    var onTapOption: () -> Void

    // MARK: - Static Date Formatters

    /// Formatter for date and time (e.g., "Jan 15, 3:30 PM")
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()

    /// Formatter for time only, respects user's locale
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        let options = activeOptions

        if !options.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { option in
                        OptionPillButton(
                            icon: option.icon,
                            text: option.text,
                            action: onTapOption
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 44)
        }
    }

    /// Returns array of active (non-default) options to display
    private var activeOptions: [OptionSummary] {
        var summaries: [OptionSummary] = []

        // Time Preference
        if tripPlannerVM.timePreference != .leaveNow {
            let timeText = formatTimePreference()
            summaries.append(OptionSummary(
                id: "time",
                icon: tripPlannerVM.timePreference.iconName,
                text: timeText
            ))
        }

        // Wheelchair Accessible
        if tripPlannerVM.isWheelchairAccessible {
            summaries.append(OptionSummary(
                id: "wheelchair",
                icon: "figure.roll",
                text: "Wheelchair accessible"
            ))
        }

        // Route Preference
        if tripPlannerVM.routePreference != .fastestTrip {
            summaries.append(OptionSummary(
                id: "route",
                icon: tripPlannerVM.routePreference.iconName,
                text: tripPlannerVM.routePreference.title
            ))
        }

        // Walking Distance
        if tripPlannerVM.maxWalkingDistance != .oneMile {
            summaries.append(OptionSummary(
                id: "walking",
                icon: "figure.walk",
                text: formatWalkingDistance()
            ))
        }

        return summaries
    }

    /// Formats the time preference for display
    private func formatTimePreference() -> String {
        switch tripPlannerVM.timePreference {
        case .leaveNow:
            return "Leave Now"
        case .departAt:
            if let date = tripPlannerVM.departureDate, let time = tripPlannerVM.departureTime {
                return "Depart at \(formatTime(date: date, time: time))"
            }
            return "Depart At"
        case .arriveBy:
            if let date = tripPlannerVM.departureDate, let time = tripPlannerVM.departureTime {
                return "Arrive by \(formatTime(date: date, time: time))"
            }
            return "Arrive By"
        }
    }

    /// Formats date and time into readable string
    private func formatTime(date: Date, time: Date) -> String {
        let calendar = Calendar.current

        // Combine date and time components
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        guard let combinedDate = calendar.date(from: combined) else {
            return formatTimeOnly(time)
        }

        // Check if it's today
        if calendar.isDateInToday(combinedDate) {
            return formatTimeOnly(time)
        }

        // Check if it's tomorrow
        if calendar.isDateInTomorrow(combinedDate) {
            return "Tomorrow \(formatTimeOnly(time))"
        }

        // Otherwise show date and time
        return Self.dateTimeFormatter.string(from: combinedDate)
    }

    /// Formats time only, respects user's locale (e.g., "3:30 PM" or "15:30")
    private func formatTimeOnly(_ time: Date) -> String {
        Self.timeFormatter.string(from: time)
    }

    /// Formats walking distance for display
    private func formatWalkingDistance() -> String {
        let distance = tripPlannerVM.maxWalkingDistance
        switch distance {
        case .quarterMile:
            return "0.25 mi walk"
        case .halfMile:
            return "0.5 mi walk"
        case .oneMile:
            return "1 mi walk"
        case .twoMiles:
            return "2 mi walk"
        }
    }
}

/// Represents a single option summary
private struct OptionSummary: Identifiable {
    let id: String
    let icon: String
    let text: String
}

/// A pill-shaped button for displaying an option
private struct OptionPillButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("With Options") {
    @Previewable @StateObject var viewModel = PreviewHelpers.mockTripPlannerViewModel()

    VStack(spacing: 20) {
        TripOptionsSummaryView(onTapOption: {
            print("Option tapped")
        })
        .environmentObject(viewModel)
        .onAppear {
            viewModel.timePreference = .arriveBy
            viewModel.departureDate = Date()
            viewModel.departureTime = Date()
            viewModel.isWheelchairAccessible = true
            viewModel.routePreference = .fewestTransfers
        }

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("No Options (Hidden)") {
    @Previewable @StateObject var viewModel = PreviewHelpers.mockTripPlannerViewModel()

    VStack(spacing: 20) {
        TripOptionsSummaryView(onTapOption: {
            print("Option tapped")
        })
        .environmentObject(viewModel)

        Text("Summary view should be hidden when all options are at defaults")
            .foregroundStyle(.secondary)

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
