//
//  Location.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation

/// Location is the main model for defining favorite location, recent location, map points
import CoreLocation

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
