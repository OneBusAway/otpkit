//
//  OriginDestinationSheetViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation
import SwiftUI

/// ViewModel for OriginDestinationSheetView
/// Handles search, location selection, favorites, and recent locations logic
@Observable
final class OriginDestinationSheetViewModel: BaseViewModel {

    // MARK: - Dependencies
    private let tripPlannerService: TripPlannerService
    private let sheetEnvironment: OriginDestinationSheetEnvironment
    private let userDefaultsService: UserDefaultsServices

    // MARK: - Published Properties

    /// Current search text
    var searchText: String = ""

    /// Search focus state
    var isSearchFocused: Bool = false

    /// Current location type being selected
    var currentLocationType: LocationType {
        tripPlannerService.originDestinationState == .origin ? .origin : .destination
    }

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

    /// Page title based on current selection type
    var pageTitle: String {
        "Choose \(currentLocationType.capitalizedName)"
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

    /// Recent locations limited to 5 items
    var limitedRecentLocations: [Location] {
        Array(recentLocations.prefix(5))
    }

    /// Should show current user section
    var shouldShowCurrentUserSection: Bool {
        searchText.isEmpty && isSearchFocused && currentUserLocation != nil
    }

    /// Should show location selection section
    var shouldShowLocationSelectionSection: Bool {
        searchText.isEmpty && !isSearchFocused
    }

    /// Should show favorites section
    var shouldShowFavoritesSection: Bool {
        searchText.isEmpty && !isSearchFocused
    }

    /// Should show recents section
    var shouldShowRecentsSection: Bool {
        searchText.isEmpty && !isSearchFocused && !recentLocations.isEmpty
    }

    /// Should show search results
    var shouldShowSearchResults: Bool {
        !searchText.isEmpty
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

    /// Handles location selection and updates trip planner
    func selectLocation(_ location: Location) {
        updateTripPlanner(for: location)
        saveToRecentLocations(location)
    }

    /// Selects current user location
    func selectCurrentUserLocation() {
        guard let userLocation = currentUserLocation else {
            handleError(OTPKitError.locationUnavailable)
            return
        }
        selectLocation(userLocation)
    }

    /// Triggers map marking mode
    func selectLocationOnMap() {
        tripPlannerService.toggleMapMarkingMode(true)
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

    /// Removes location from favorites
    public func removeFromFavorites(_ location: Location) {
        executeTask {
            switch self.userDefaultsService.deleteFavoriteLocationData(with: location.id) {
            case .success:
                await MainActor.run {
                    self.sheetEnvironment.refreshFavoriteLocations()
                }
            case .failure(let error):
                throw OTPKitError.deleteFailed("favorite location: \(error.localizedDescription)")
            }
        }
    }

    /// Refreshes data when view appears
    func onViewAppear() {
        sheetEnvironment.refreshFavoriteLocations()
        sheetEnvironment.refreshRecentLocations()
    }

    // MARK: - Private Methods

    private func updateTripPlanner(for location: Location) {
        tripPlannerService.appendMarker(location: location)
        tripPlannerService.addOriginDestinationData()
    }

    private func saveToRecentLocations(_ location: Location) {
        switch userDefaultsService.saveRecentLocations(data: location) {
        case .success:
            break // Silent success for recent locations
        case .failure:
            break // Don't show error for recent locations failure
        }
    }
}
