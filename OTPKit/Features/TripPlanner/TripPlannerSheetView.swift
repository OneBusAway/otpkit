//
//  TripPlannerSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 25/07/24.
//

import SwiftUI

public struct TripPlannerSheetView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared
    @Environment(\.dismiss) var dismiss

    public init() {}

    private func formatTimeDuration(_ duration: Int) -> String {
        if duration < 60 {
            return "Total duration: \(duration) second\(duration > 1 ? "s" : "")"
        } else if duration < 3600 {
            let minutes = Double(duration) / 60
            return String(format: "Total duration: %.1f minutes", minutes)
        } else {
            let hours = Double(duration) / 3600
            return String(format: "Total duration: %.1f hours", hours)
        }
    }

    private func formatDistance(_ distance: Int) -> String {
        if distance < 1000 {
            return "Total distance: \(distance) meters"
        } else {
            let miles = Double(distance) / 1609.34
            return String(format: "Total distance: %.1f miles", miles)
        }
    }

    public var body: some View {
        VStack {
            if let itineraries = locationManagerService.planResponse?.plan?.itineraries {
                List(itineraries, id: \.self) { itinerary in
                    let distance = itinerary.legs.map(\.distance).reduce(0, +)
                    Button(action: {
                        locationManagerService.selectedIternary = itinerary
                        locationManagerService.planResponse = nil
                        dismiss()
                    }, label: {
                        VStack(alignment: .leading) {
                            Text(formatTimeDuration(itinerary.duration))
                            Text(formatDistance(Int(distance)))
                        }

                    })
                }
            } else {
                Text("Can't find trip planner. Please try another pin point")
            }

            Button(action: {
                locationManagerService.resetTripPlanner()
                dismiss()
            }, label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
            })
        }
    }
}

#Preview {
    TripPlannerSheetView()
}
