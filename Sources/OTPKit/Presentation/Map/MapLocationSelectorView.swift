//
//  MapLocationSelectorView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import CoreLocation
import MapKit
import SwiftUI

public struct MapLocationSelectorView: View {
    @Environment(\.otpTheme) private var theme
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel

    let locationMode: LocationMode
    private let locationManager = LocationManager.shared

    // MARK: - Constants
    private enum Constants {
        static let haloLineWidth: CGFloat = 5
        static let mainLineWidth: CGFloat = 4
        static let haloOpacity: Double = 0.8
        static let stationDotSize: CGFloat = 10
        static let stationDotBorderWidth: CGFloat = 2
        static let iconSize: CGFloat = 14
        static let iconPadding: CGFloat = 6
    }

    public init(
        locationMode: LocationMode
    ){
        self.locationMode = locationMode
    }

    public var body: some View {
        MapReader { mapProxy in
            Map(position: $tripPlannerVM.region) {
                locationAnnotations
                routeOverlay
                stationDots
                legModeAnnotations

                UserAnnotation()
            }
            .tint(theme.primaryColor)
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
                MapScaleView()
            }
            .onTapGesture { location in
                handleMapTap(at: location, with: mapProxy)
            }
        }
    }
}

// MARK: - Map Content
private extension MapLocationSelectorView {
    @MapContentBuilder
    var locationAnnotations: some MapContent {
        if let origin = tripPlannerVM.selectedOrigin {
            locationAnnotation(for: origin,
                               titleKey: Localization.string("map.origin"),
                               color: theme.primaryColor)
        }

        if let destination = tripPlannerVM.selectedDestination {
            locationAnnotation(for: destination,
                               titleKey: Localization.string("map.destination"),
                               color: theme.primaryColor)
        }
    }

    /// Renders colored polylines for each leg of the trip itinerary
    /// Uses strategic colors: gray (walking), blue (transit), orange (personal transport)
    @MapContentBuilder
    var routeOverlay: some MapContent {
        if tripPlannerVM.showingPolyline, let itinerary = tripPlannerVM.selectedItinerary {
            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
                if let coordinates = leg.decodePolyline(), !coordinates.isEmpty {
                    let polyline = MapPolyline(coordinates: coordinates)
                    let legColor = colorForLegMode(leg.mode)

                    // White halo for better visibility
                    polyline.stroke(Color.white.opacity(Constants.haloOpacity), style: StrokeStyle(lineWidth: Constants.haloLineWidth, lineCap: .round))
                    // Colored route for each leg
                    polyline.stroke(legColor, style: StrokeStyle(lineWidth: Constants.mainLineWidth, lineCap: .round))
                }
            }
        }
    }

    /// Displays transport mode icons at the midpoint of each leg
    @MapContentBuilder
    var legModeAnnotations: some MapContent {
        if tripPlannerVM.showingPolyline, let itinerary = tripPlannerVM.selectedItinerary {
            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
                if let coordinates = leg.decodePolyline(), !coordinates.isEmpty {
                    // Use midpoint of each leg for icon placement
                    let midIndex = coordinates.count / 2
                    let position = coordinates[midIndex]

                    Annotation("", coordinate: position) {
                        Image(systemName: iconForLegMode(leg.mode))
                            .foregroundColor(.white)
                            .font(.system(size: Constants.iconSize, weight: .medium))
                            .padding(Constants.iconPadding)
                            .background(Circle().fill(colorForLegMode(leg.mode)))
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
    }

    /// Shows station/stop annotations with names for transit stations
    @MapContentBuilder
    var stationDots: some MapContent {
        if tripPlannerVM.showingPolyline, let itinerary = tripPlannerVM.selectedItinerary {
            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
                // Add dot for the "from" location (start of leg)
                if shouldShowStationDot(for: leg.from) {
                    createStationAnnotation(for: leg.from)
                }

                // Add dot for the "to" location (end of leg) - only for the last leg
                if index == itinerary.legs.count - 1 && shouldShowStationDot(for: leg.to) {
                    createStationAnnotation(for: leg.to)
                }
            }
        }
    }

    func locationAnnotation(
        for location: Location,
        titleKey: String,
        color: Color,
        systemImage: String = "mappin.circle.fill"
    ) -> some MapContent {
        Marker(titleKey, systemImage: systemImage, coordinate: location.coordinate)
            .tint(color)
            .annotationTitles(.visible)
    }
}

// MARK: - Event Handlers
private extension MapLocationSelectorView {
    func handleMapTap(at location: CGPoint, with mapProxy: MapProxy) {
        guard !tripPlannerVM.showingPolyline,
              let coordinate = mapProxy.convert(location, from: .local) else { return }

        let tempLocation = Location(
            title: Localization.string("map.finding"),
            subTitle: Localization.string("map.searching_address"),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        updateSelectedLocation(with: tempLocation)

        Task {
            if let geocodedLocation = await locationManager.reverseGeocode(coordinate: coordinate) {
                updateSelectedLocation(with: geocodedLocation)
            }
        }
    }

    func updateSelectedLocation(with location: Location) {
        tripPlannerVM.handleLocationSelection(location, for: locationMode)
    }
}

// MARK: - Transport Mode Helpers
private extension MapLocationSelectorView {
    /// Returns the appropriate SF Symbol icon for a given transport mode
    func iconForLegMode(_ mode: String) -> String {
        switch mode.uppercased() {
        case "WALK":
            return "figure.walk"
        case "BUS":
            return "bus"
        case "TRAM":
            return "tram"
        case "BIKE":
            return "bicycle"
        case "CAR":
            return "car"
        case "TRAIN", "SUBWAY":
            return "train.side.front.car"
        case "FERRY":
            return "ferry"
        default:
            return "questionmark"
        }
    }

    /// Returns strategic color for transport mode: gray (walking), blue (transit), orange (personal)
    func colorForLegMode(_ mode: String) -> Color {
        switch mode.uppercased() {
        case "WALK":
            return .gray
        case "BUS", "TRAM", "TRAIN", "SUBWAY", "FERRY":
            return theme.primaryColor
        case "BIKE", "CAR":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Station Helpers
private extension MapLocationSelectorView {
    /// Determines if a place should display a station dot (stops and stations only)
    func shouldShowStationDot(for place: Place) -> Bool {
        return place.vertexType == "STOP" || place.vertexType == "STATION" || place.stopId != nil
    }

    /// Creates a station annotation with a blue-outlined white dot and station name
    @MapContentBuilder
    func createStationAnnotation(for place: Place) -> some MapContent {
        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)) {
            Circle()
                .fill(Color.white)
                .frame(width: Constants.stationDotSize, height: Constants.stationDotSize)
                .overlay(
                    Circle()
                        .stroke(Color(.systemBlue), lineWidth: Constants.stationDotBorderWidth)
                )
        }
    }

}

#Preview {
    @Previewable @StateObject var vm = PreviewHelpers.mockTripPlannerViewModel()

    MapLocationSelectorView(
        locationMode: .origin
    )
    .environmentObject(vm)
    .onAppear {
        let cafe = PreviewHelpers.createOrigin()
        vm.selectedOrigin = cafe

        vm.changeMapCamera(to: cafe.coordinate)
    }
}
