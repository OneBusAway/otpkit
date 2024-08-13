//
//  Location.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation

/// Location is the main model for defining favorite location, recent location, map points
public struct Location: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public let title: String
    public let subTitle: String
    public let latitude: Double
    public let longitude: Double

    public init(id: UUID = UUID(), title: String, subTitle: String, latitude: Double, longitude: Double) {
        self.id = id
        self.title = title
        self.subTitle = subTitle
        self.latitude = latitude
        self.longitude = longitude
    }
}
