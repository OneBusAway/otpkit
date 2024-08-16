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
/// - selectedValue: responsible for managing selected value when user taped the list in `OriginDestinationSheetView
@Observable
public final class OriginDestinationSheetEnvironment {
    public var isSheetOpened = false
    public var selectedValue: String = ""

    // This responsible for showing favorite locations and recent locations in sheets
    public var favoriteLocations: [Location] = []
    public var recentLocations: [Location] = []

    /// Selected detail favorite locations that will be shown in `FavoriteLocationDetailSheet`
    public var selectedDetailFavoriteLocation: Location?
    
    public var isSheetOpenedBinding: Binding<Bool> {
        Binding(
            get: { self.isSheetOpened },
            set: { newValue in self.isSheetOpened = newValue }
        )
    }

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
