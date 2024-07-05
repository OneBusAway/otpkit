//
//  OriginDestinationSheetEnvironment.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation
import OTPKit

/// OriginDestinationSheetState responsible for managing states of the shown `OriginDestinationSheetView`
/// - Enums:
///     - origin: This manage origin state of the trip planner
///     - destination: This manage destination state of the trip planner
public enum OriginDestinationSheetState {
    case origin
    case destination
}

/// OriginDestinationSheetEnvironment responsible for manage the environment of `OriginDestination` features
/// - sheetState: responsible for managing shown sheet in `OriginDestinationView`
/// - selectedValue: responsible for managing selected value when user taped the list in `OriginDestinationSheetView`
public final class OriginDestinationSheetEnvironment: ObservableObject {
    @Published var sheetState: OriginDestinationSheetState = .origin
    @Published var selectedValue: String = ""

    // This responsible for showing favorite locations and recent locations in sheets
    @Published var favoriteLocations: [Location] = []
    @Published var recentLocations: [Location] = []

    /// Selected detail favorite locations that will be shown in `FavoriteLocationDetailSheet`
    @Published var selectedDetailFavoriteLocation: Location?

    /// Refresh favorite locations data from user defaults
    func refreshFavoriteLocations() {
        switch UserDefaultsServices.shared.getFavoriteLocationsData() {
        case let .success(locations):
            favoriteLocations = locations
        case let .failure(error):
            print("Failed to refresh favorite locations: \(error)")
        }
    }

    /// Refresh recent locations data from user defaults
    func refreshRecentLocations() {
        switch UserDefaultsServices.shared.getRecentLocations() {
        case let .success(locations):
            recentLocations = locations
        case let .failure(error):
            print("Failed to refresh favorite locations: \(error)")
        }
    }
}
