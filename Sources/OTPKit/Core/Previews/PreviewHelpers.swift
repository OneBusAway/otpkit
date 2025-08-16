//
//  PreviewHelpers.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import CoreLocation
import MapKit
import SwiftUI

class PreviewHelpers {
   

    static func buildLeg() -> Leg {
        Leg(
            startTime: Date(),
            endTime: Date(),
            mode: "TRAM",
            route: nil,
            agencyName: nil,
            from: Place(name: "foo", lon: 47, lat: -122, vertexType: ""),
            to: Place(name: "foo", lon: 47, lat: -122, vertexType: ""),
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 100,
            transitLeg: false,
            duration: 10,
            realTime: true,
            streetNames: nil,
            pathway: nil,
            steps: nil,
            headsign: nil
        )
    }
}
