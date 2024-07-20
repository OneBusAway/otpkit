//
//  OriginDestinationSheetEnvironment.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation
import SwiftUI

/// OriginDestinationSheetEnvironment responsible for manage the environment of `OriginDestination` features
/// - sheetState: responsible for managing shown sheet in `OriginDestinationView`
/// - selectedValue: responsible for managing selected value when user taped the list in `OriginDestinationSheetView`
public final class OriginDestinationSheetEnvironment: ObservableObject {
    @Published public var isSheetOpened = false
    @Published public var selectedValue: String = ""

    // This responsible for showing favorite locations and recent locations in sheets
    @Published public var favoriteLocations: [Location] = []
    @Published public var recentLocations: [Location] = []

    /// Selected detail favorite locations that will be shown in `FavoriteLocationDetailSheet`
    @Published public var selectedDetailFavoriteLocation: Location?

    // Public initializer
    public init() {}

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
