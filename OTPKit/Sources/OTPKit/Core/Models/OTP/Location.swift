//
//  Location.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation
import CoreLocation

/// Location is the main model for defining favorite location, recent location, map points
public struct Location: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public let title: String
    public let subTitle: String
    public let latitude: Double
    public let longitude: Double
    public var date: Date = Date()

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(id: UUID = UUID(), title: String, subTitle: String, latitude: Double, longitude: Double) {
        self.id = id
        self.title = title
        self.subTitle = subTitle
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Builds the "Current Location" entry shown wherever the user's own position is offered
    /// as an origin or destination. Centralized so its localized title and subtitle stay in
    /// sync across the location manager and the picker sheet.
    public static func currentLocation(from coordinate: CLLocationCoordinate2D) -> Location {
        Location(
            title: OTPLoc("location_picker.current_location_title", comment: "Name given to the device's location"),
            subTitle: OTPLoc("location_picker.gps_location_subtitle", comment: "Subtitle for the device's location"),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    public static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.title == rhs.title &&
        lhs.subTitle == rhs.subTitle &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subTitle)
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
