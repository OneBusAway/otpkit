//
//  LibraryViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-08-28.
//

import Foundation
import SwiftUI

@Observable
class LibraryViewModel {
    var favoriteLocations: [Location] = []
    var isLoadingFavorites = true

    private let maxDisplayCount = 4

    var displayedFavorites: [Location] {
        Array(favoriteLocations.prefix(maxDisplayCount - (hasMoreFavorites ? 1 : 0)))
    }

    var hasMoreFavorites: Bool {
        favoriteLocations.count > maxDisplayCount
    }

    var shouldShowFavoritesSection: Bool {
        !favoriteLocations.isEmpty || isLoadingFavorites
    }

    func loadFavoriteLocations() {
        isLoadingFavorites = true

        switch UserDefaultsServices.shared.getFavoriteLocationsData() {
        case .success(let locations):
            favoriteLocations = locations
        case .failure:
            favoriteLocations = []
        }

        isLoadingFavorites = false
    }

    func selectLocation(_ location: Location, onLocationSelected: (Location) -> Void) {
        onLocationSelected(location)
    }
}
