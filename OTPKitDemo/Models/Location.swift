//
//  Location.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation

struct Location: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let subTitle: String
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), title: String, subTitle: String, latitude: Double, longitude: Double) {
        self.id = id
        self.title = title
        self.subTitle = subTitle
        self.latitude = latitude
        self.longitude = longitude
    }
}
