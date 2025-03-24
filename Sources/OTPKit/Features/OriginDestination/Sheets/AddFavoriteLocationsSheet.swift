//
//  AddFavoriteLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

/// This sheet responsible to add a new favorite location.
/// Users can search and add their favorite locations
public struct AddFavoriteLocationsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner

    @State private var search = ""

    @FocusState private var isSearchFocused: Bool

    @State private var isAllRecentPresented: Bool = false

    private var filteredCompletions: [Location] {
        let favorites = sheetEnvironment.favoriteLocations
        return tripPlanner.completions.filter { completion in
            !favorites.contains { favorite in
                favorite.title == completion.title &&
                favorite.subTitle == completion.subTitle &&
                favorite.latitude == completion.latitude &&
                favorite.longitude == completion.longitude
            }
        }
    }

    private var filteredRecentLocations: [Location] {
        let favorites = sheetEnvironment.favoriteLocations
        return sheetEnvironment.recentLocations.filter { recent in
            !favorites.contains { favorite in
                favorite.title == recent.title &&
                favorite.subTitle == recent.subTitle &&
                favorite.latitude == recent.latitude &&
                favorite.longitude == recent.longitude
            }
        }
    }

    private var isCurrentLocationFavorite: Bool {
        guard let currentLocation = tripPlanner.currentLocation else { return false }
        return sheetEnvironment.favoriteLocations.contains { favorite in
            favorite.title == currentLocation.title &&
            favorite.subTitle == currentLocation.subTitle &&
            favorite.latitude == currentLocation.latitude &&
            favorite.longitude == currentLocation.longitude
        }
    }

    private func saveFavoriteLocation(_ location: Location) {
        switch UserDefaultsServices.shared.saveFavoriteLocationData(data: location) {
        case .success:
            sheetEnvironment.refreshFavoriteLocations()
            dismiss()
        case let .failure(error):
            print(error)
        }
    }

    private func currentUserSection() -> some View {
        if search.isEmpty, let userLocation = tripPlanner.currentLocation, !isCurrentLocationFavorite {
            AnyView(
                AddFavoriteCell(
                    title: userLocation.title,
                    subtitle: userLocation.subTitle,
                    action: {

                        switch UserDefaultsServices.shared.saveFavoriteLocationData(data: userLocation) {
                        case .success:
                            sheetEnvironment.refreshFavoriteLocations()
                            dismiss()
                        case let .failure(error):
                            print(error)
                        }
                    })
            )

        } else {
            AnyView(EmptyView())
        }
    }

    private func searchedResultsSection() -> some View {

        if filteredCompletions.isEmpty {
            return AnyView(
                NoResultsView(
                    iconName: "magnifyingglass",
                    title: "No results found",
                    subtitle: "Try searching for another location"
                )
            )
         
        }
        
        return AnyView(
            ForEach(filteredCompletions) { location in
                AddFavoriteCell(title: location.title, subtitle: location.subTitle, action: {
                    saveFavoriteLocation(location)
                })
            }
        )
    }
    
    private func recentLocationsSection() -> some View {
        
        guard filteredRecentLocations.count > 0 else {
            return AnyView(
                NoResultsView(
                    iconName: "clock",
                    title: "No recent locations",
                    subtitle: "All recent locations have been added to favorites"
                )
            )
        }
        
        return AnyView(
            Section(content: {
                ForEach(Array(filteredRecentLocations.prefix(5)), content: { location in
                    VStack(alignment: .leading) {
                        
                        AddFavoriteCell(title: location.title, subtitle: location.subTitle) {
                            saveFavoriteLocation(location)
                        }
                    }
                })
            }, header: {
                SectionHeaderView(text: "Recents", action: {
                    isAllRecentPresented = true
                })
            })
            
        )
    }

    public var body: some View {
        VStack {
            PageHeaderView(text: "Add Favorite") {
                dismiss()
            }
            .padding()
            
            SearchView(placeholder: "Search for a place", searchText: $search, isSearchFocused: _isSearchFocused)
                .padding(.horizontal, 16)
            
            List {
                if search.isEmpty, !isSearchFocused {
                    currentUserSection()
                    recentLocationsSection()
                } else {
                    searchedResultsSection()
                }
            }
            .onChange(of: search) { _, searchValue in
                tripPlanner.updateQuery(queryFragment: searchValue)
            }
            .sheet(isPresented: $isAllRecentPresented) {
                // Add selected most recent location to favorite if is not already in the favorites list
                if let selectedLocation = sheetEnvironment.selectedRecentLocation,
                   !sheetEnvironment.favoriteLocations.contains(selectedLocation) {
                    saveFavoriteLocation(selectedLocation)
                }
                sheetEnvironment.selectedRecentLocation = nil
            } content: {
                MoreRecentLocationsSheet()
            }
            
        }
    }
}

#Preview {
    AddFavoriteLocationsSheet()
}
