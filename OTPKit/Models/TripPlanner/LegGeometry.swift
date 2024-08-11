//
//  LegGeometry.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/10/24.
//

import Foundation

/// A container for the polyline of a `Leg`.
public struct LegGeometry: Codable, Hashable {
    /// The raw polyline; encoded with the Google Polyline Algorithm Format.
    public let points: String

    /// The number of coordinates represented by `points`.
    public let length: Int
}
