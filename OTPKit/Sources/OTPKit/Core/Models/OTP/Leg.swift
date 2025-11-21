/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CoreLocation
import Foundation
import SwiftUI
import MapKit

// swiftlint:disable identifier_name

public enum RouteType: Int, Codable {
    case nonTransit = -1
    case tram = 0
    case subway = 1
    case train = 2
    case bus = 3
    case ferry = 4
    case cableCar = 5
    case gondola = 6
    case funicular = 7
}

/// Represents a single segment or leg of a travel itinerary.
public struct Leg: Codable, Hashable {
    /// Start time of the leg.
    public let startTime: Date

    /// End time of the leg.
    public let endTime: Date

    /// Mode of transportation used in this leg (e.g., "BUS", "TRAIN").
    public let mode: String

    /// true if this Leg represents a walking step.
    public var walkMode: Bool {
        mode.lowercased() == "walk"
    }

    public let routeType: RouteType?

    public let routeColor: String?
    public let routeTextColor: String?

    /// Optional route identifier for this leg.
    public let route: String?

    /// Optional name of the transportation agency for this leg.
    public let agencyName: String?

    /// Starting point of the leg.
    public let from: Place

    /// Ending point of the leg.
    public let to: Place

    /// A container for the polyline of this leg.
    public let legGeometry: LegGeometry

    /// Distance covered in this leg, in meters.
    public let distance: Double

    /// Optional flag indicating whether this leg involves transit.
    public let transitLeg: Bool?

    /// Duration of the leg in seconds.
    public let duration: Int

    /// Optional flag indicating if the leg details are based on real-time data.
    public let realTime: Bool?

    /// Optional list of street names traversed in this leg.
    public let streetNames: [String]?

    /// Optional flag indicating whether the leg involves a pathway.
    public let pathway: Bool?

    /// Optional detailed steps for navigating this leg.
    public let steps: [Step]?

    /// Optional head sign of the transit legs, bus and trams
    public let headsign: String?

    /// Optional list of intermediate stops along this transit leg
    public let intermediateStops: [Place]?

    /// Merges `Itinerary` `Leg`s that are part of the same route on the same vehicle.
    /// - Parameters:
    ///   - leg1: The earlier leg
    ///   - leg2: The later leg
    /// - Returns: A merged Leg object
    public static func mergeLegs(leg1: Leg, leg2: Leg) -> Leg {
        return Leg(
            startTime: leg1.startTime,
            endTime: leg2.endTime,
            mode: leg1.mode,
            routeType: leg1.routeType,
            routeColor: leg1.routeColor,
            routeTextColor: leg1.routeTextColor,
            route: leg1.route,
            agencyName: leg1.agencyName,
            from: leg1.from,
            to: leg2.to,
            legGeometry: leg1.legGeometry,
            distance: leg1.distance + leg2.distance,
            transitLeg: leg1.transitLeg,
            duration: leg1.duration + leg2.duration,
            realTime: leg1.realTime,
            streetNames: leg1.streetNames,
            pathway: leg1.pathway,
            steps: leg1.steps,
            headsign: leg1.headsign,
            intermediateStops: leg1.intermediateStops
        )
    }

    /// Returns true if the two legs should be merged (with mergeLegs) and false otherwise.
    /// - Parameters:
    ///   - leg1: The earlier leg
    ///   - leg2: The later leg
    /// - Returns: Whether or not to merge the legs.
    public static func shouldMergeLegs(leg1: Leg, leg2: Leg) -> Bool {
        return leg1.route != nil &&
        leg2.route != nil &&
        leg1.route == leg2.route &&
        leg1.transitLeg == true &&
        leg2.transitLeg == true
    }

    // MARK: - Polyline

    /// Returns an array of `CLLocationCoordinate2D`s representing the geometry of this `Leg`.
    public func decodePolyline() -> [CLLocationCoordinate2D]? {
        OTPKit.decodePolyline(legGeometry.points)
    }

    /// Creates an `MKMapRect` from the Leg's encoded polyline.
    /// - Returns: The `MKMapRect` from the polyline or `MKMapRect.null` if the polyilne is empty or invalid.
    public var polylineMapRect: MKMapRect {
        guard let coordinates = decodePolyline(), !coordinates.isEmpty else {
            return MKMapRect.null
        }

        // Calculate bounding box for the leg
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        // Convert to MKMapRect
        let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: minLon))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: maxLon))

        let mapRect = MKMapRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(topLeft.x - bottomRight.x),
            height: abs(topLeft.y - bottomRight.y)
        )

        return mapRect
    }

    // MARK: - Computed Properties

    /// Returns a SwiftUI Color from the routeColor hex string if valid
    public var routeUIColor: Color? {
        guard let routeColor = routeColor else { return nil }
        return Color(hex: routeColor)
    }

    /// Returns a SwiftUI Color from the routeTextColor hex string if valid
    public var routeTextUIColor: Color? {
        guard let routeTextColor = routeTextColor else { return nil }
        return Color(hex: routeTextColor)
    }
}

// MARK: - Color Extension

private extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        var r, g, b: Double

        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        } else if length == 3 {
            r = Double((rgb & 0xF00) >> 8) / 15.0
            g = Double((rgb & 0x0F0) >> 4) / 15.0
            b = Double(rgb & 0x00F) / 15.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b)
    }
}

// swiftlint:enable identifier_name
