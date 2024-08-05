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
            return "\(duration) second\(duration > 1 ? "s" : "")"
        } else if duration < 3600 {
            let minutes = Double(duration) / 60
            return String(format: "%.1f min", minutes)
        } else {
            let hours = Double(duration) / 3600
            return String(format: "%.1f hours", hours)
        }
    }

    private func formatDistance(_ distance: Int) -> String {
        if distance < 1000 {
            return "\(distance) meters"
        } else {
            let miles = Double(distance) / 1609.34
            return String(format: "%.1f miles", miles)
        }
    }

    private func formatBusSchedule(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"

        let formattedTime = dateFormatter.string(from: date)

        return "Bus scheduled at \(formattedTime)"
    }

    private func generateTramView(leg: Leg) -> some View {
        HStack(spacing: 4) {
            Text(leg.route ?? "")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundStyle(.foreground)
                .font(.caption)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Image(systemName: "tram")
                .foregroundStyle(.foreground)
        }.frame(height: 40)
    }

    private func generateBusView(leg: Leg) -> some View {
        HStack(spacing: 4) {
            Text(leg.route ?? "")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .foregroundStyle(.foreground)
                .font(.caption)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Image(systemName: "bus")
                .foregroundStyle(.foreground)
        }
        .frame(height: 40)
    }

    private func generateWalkView(leg: Leg) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
            Text(formatTimeDuration(leg.duration))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .foregroundStyle(.gray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(height: 40)
    }

    private func generateDefaultView(leg: Leg) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.foreground)
            Text(formatTimeDuration(leg.duration))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .foregroundStyle(.gray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(height: 40)
    }

    private func generateLegView(leg: Leg) -> some View {
        Group {
            switch leg.mode {
            case "TRAM":
                generateTramView(leg: leg)

            case "BUS":
                generateBusView(leg: leg)

            case "WALK":
                generateWalkView(leg: leg)

            default:
                generateDefaultView(leg: leg)
            }
        }
    }

    public var body: some View {
        VStack {
            if let itineraries = locationManagerService.planResponse?.plan?.itineraries {
                List(itineraries, id: \.self) { itinerary in
                    Button(action: {
                        locationManagerService.selectedItinerary = itinerary
                        locationManagerService.planResponse = nil
                        dismiss()
                    }, label: {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text(formatTimeDuration(itinerary.duration))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.foreground)
                                Text(formatBusSchedule(itinerary.startTime))
                                    .foregroundStyle(.gray)

                                FlowLayout {
                                    ForEach(Array(zip(itinerary.legs.indices, itinerary.legs)), id: \.1) { index, leg in

                                        generateLegView(leg: leg)

                                        if index < itinerary.legs.count - 1 {
                                            VStack {
                                                Image(systemName: "chevron.right.circle.fill")
                                                    .frame(width: 8, height: 16)
                                            }.frame(height: 40)
                                        }
                                    }
                                }
                            }

                            Button(action: {
                                locationManagerService.selectedItinerary = itinerary
                                locationManagerService.planResponse = nil
                                dismiss()
                            }, label: {
                                Text("Go")
                                    .padding(30)
                                    .background(Color.green)
                                    .foregroundStyle(.foreground)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            })
                        }

                    })
                    .foregroundStyle(.foreground)
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
                    .foregroundStyle(.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
            })
        }
    }
}

#Preview {
    TripPlannerSheetView()
}
