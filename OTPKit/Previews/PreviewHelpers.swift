//
//  PreviewHelpers.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

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
            distance: 100,
            transitLeg: false,
            duration: 10,
            realTime: true,
            streetNames: nil,
            pathway: nil,
            steps: nil
        )
    }
}
