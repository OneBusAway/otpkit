//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 25/07/24.
//

import SwiftUI

public struct TripPlannerView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared

    public init() {}
    public var body: some View {
        if let itineraries = locationManagerService.planResponse?.plan?.itineraries {
            List(itineraries, id: \.self) { itinerary in
                Text(String(itinerary.duration))
            }
        } else {
            Text("Can't find location")
        }
    }
}

#Preview {
    TripPlannerView()
}
