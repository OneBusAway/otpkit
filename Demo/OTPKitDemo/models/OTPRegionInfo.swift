//
//  OTPRegionInfo.swift
//  OTPKitDemo
//
//  Created by Aaron Brethorst on 10/30/25.
//

import Foundation
import CoreLocation

struct OTPRegionInfo: Codable {
    /// Which OTP API flavor the region's server speaks.
    enum APIType: String, Codable {
        /// OTP 1.x REST API
        case rest
        /// OTP 2.x GTFS GraphQL API
        case graphQL
    }

    let name: String
    let description: String
    let icon: String
    let url: URL
    let center: CLLocationCoordinate2D
    let apiType: APIType

    enum CodingKeys: String, CodingKey {
        case name, description, icon, url, apiType
        case latitude, longitude
    }

    init(name: String, description: String, icon: String, url: URL, center: CLLocationCoordinate2D, apiType: APIType = .rest) {
        self.name = name
        self.description = description
        self.icon = icon
        self.url = url
        self.center = center
        self.apiType = apiType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        icon = try container.decode(String.self, forKey: .icon)
        url = try container.decode(URL.self, forKey: .url)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        // Regions persisted before apiType existed are REST servers.
        apiType = try container.decodeIfPresent(APIType.self, forKey: .apiType) ?? .rest
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(icon, forKey: .icon)
        try container.encode(url, forKey: .url)
        try container.encode(center.latitude, forKey: .latitude)
        try container.encode(center.longitude, forKey: .longitude)
        try container.encode(apiType, forKey: .apiType)
    }
}
