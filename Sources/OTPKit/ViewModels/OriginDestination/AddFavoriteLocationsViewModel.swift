//
//  AddFavoriteLocationsViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation
import SwiftUI

/// ViewModel for AddFavoriteLocationsSheet
/// Handles search, filtering, and favorite location management
@Observable
final class AddFavoriteLocationsViewModel: BaseViewModel {

    // MARK: - Dependencies
    private let tripPlannerService: TripPlannerService
    private let sheetEnvironment: OriginDestinationSheetEnvironment
    private let userDefaultsService: UserDefaultsServices

    // MARK: - Published Properties

    /// Current search text
    var searchText: String = ""

    /// Search focus state
    var isSearchFocused: Bool = false

    /// Search completions from the trip planner service
    var searchCompletions: [Location] {
        tripPlannerService.completions
    }

    /// Favorite locations
    var favoriteLocations: [Location] {
        sheetEnvironment.favoriteLocations
    }

    /// Recent locations
    var recentLocations: [Location] {
        sheetEnvironment.recentLocations
    }

    /// Current user location
    var currentUserLocation: Location? {
        tripPlannerService.currentLocation
    }

    // MARK: - Computed Properties

    /// Filtered completions (excludes favorites)
    var filteredCompletions: [Location] {
        let favorites = favoriteLocations
        return searchCompletions.filter { completion in
            !favorites.contains { favorite in
                favorite.title == completion.title &&
                favorite.subTitle == completion.subTitle &&
                favorite.latitude == completion.latitude &&
                favorite.longitude == completion.longitude
            }
        }
    }

    /// Recent locations filtered to exclude existing favorites
    var filteredRecentLocations: [Location] {
        let favorites = favoriteLocations
        return recentLocations.filter { recent in
            !favorites.contains { favorite in
                favorite.title == recent.title &&
                favorite.subTitle == recent.subTitle &&
                favorite.latitude == recent.latitude &&
                favorite.longitude == recent.longitude
            }
        }
    }

    /// Recent locations limited to 5 items
    var limitedRecentLocations: [Location] {
        Array(filteredRecentLocations.prefix(5))
    }

    /// Check if current location is already in favorites
    var isCurrentLocationFavorite: Bool {
        guard let currentLocation = currentUserLocation else { return false }
        return favoriteLocations.contains { favorite in
            favorite.title == currentLocation.title &&
            favorite.subTitle == currentLocation.subTitle &&
            favorite.latitude == currentLocation.latitude &&
            favorite.longitude == currentLocation.longitude
        }
    }

    /// Should show current user section
    var shouldShowCurrentUserSection: Bool {
        searchText.isEmpty && currentUserLocation != nil && !isCurrentLocationFavorite
    }

    /// Should show recent locations section
    var shouldShowRecentLocationsSection: Bool {
        searchText.isEmpty && !isSearchFocused && !filteredRecentLocations.isEmpty
    }

    /// Should show search results
    var shouldShowSearchResults: Bool {
        !searchText.isEmpty
    }

    /// Should show no results for search
    var shouldShowNoSearchResults: Bool {
        shouldShowSearchResults && filteredCompletions.isEmpty
    }

    /// Should show no recent locations message
    var shouldShowNoRecentLocations: Bool {
        searchText.isEmpty && !isSearchFocused && filteredRecentLocations.isEmpty
    }

    // MARK: - Initialization

    init(tripPlannerService: TripPlannerService,
         sheetEnvironment: OriginDestinationSheetEnvironment,
         userDefaultsService: UserDefaultsServices) {
        self.tripPlannerService = tripPlannerService
        self.sheetEnvironment = sheetEnvironment
        self.userDefaultsService = userDefaultsService
        super.init()
    }

    // MARK: - Public Methods

    /// Updates search query and triggers completion search
    func updateSearchQuery(_ query: String) {
        searchText = query
        tripPlannerService.updateQuery(queryFragment: query)
    }

    /// Adds location to favorites
    func addToFavorites(_ location: Location) {
        executeTask {
            switch self.userDefaultsService.saveFavoriteLocationData(data: location) {
            case .success:
                await MainActor.run {
                    self.sheetEnvironment.refreshFavoriteLocations()
                }
            case .failure(let error):
                throw OTPKitError.saveFailed("favorite location: \(error.localizedDescription)")
            }
        }
    }

    /// Adds current user location to favorites
    func addCurrentUserLocationToFavorites() {
        guard let userLocation = currentUserLocation else {
            handleError(OTPKitError.locationUnavailable)
            return
        }
        addToFavorites(userLocation)
    }

    /// Refreshes data when view appears
    func onViewAppear() {
        sheetEnvironment.refreshFavoriteLocations()
        sheetEnvironment.refreshRecentLocations()
    }
}
