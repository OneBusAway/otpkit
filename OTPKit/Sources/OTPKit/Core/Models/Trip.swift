//
//  Trip.swift
//  
//
//  Created by Aaron Brethorst on 10/29/25.
//

import Foundation

/// Encapsulates all of the necessary information to plot out a trip on the map and in a details pane.
struct Trip: Equatable, Hashable {
    let origin: Location
    let destination: Location
    let itinerary: Itinerary
}
