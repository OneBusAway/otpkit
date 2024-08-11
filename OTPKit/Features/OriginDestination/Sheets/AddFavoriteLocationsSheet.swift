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
    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment
    @EnvironmentObject private var tripPlanner: TripPlannerService

    @State private var search = ""

    @FocusState private var isSearchFocused: Bool

    private var filteredCompletions: [Location] {
        let favorites = sheetEnvironment.favoriteLocations
        return tripPlanner.completions.filter { completion in
            !favorites.contains { favorite in
                favorite.title == completion.title &&
                    favorite.subTitle == completion.subTitle
            }
        }
    }

    private func currentUserSection() -> some View {
        if search.isEmpty, let userLocation = tripPlanner.currentLocation {
            AnyView(
                Button(action: {
                    switch UserDefaultsServices.shared.saveFavoriteLocationData(data: userLocation) {
                    case .success:
                        sheetEnvironment.refreshFavoriteLocations()
                        dismiss()
                    case let .failure(error):
                        print(error)
                    }
                }, label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(userLocation.title)
                                .font(.headline)
                            Text(userLocation.subTitle)
                        }.foregroundStyle(.foreground)

                        Spacer()

                        Image(systemName: "plus")
                    }

                })
            )

        } else {
            AnyView(EmptyView())
        }
    }

    private func searchedResultsSection() -> some View {
        ForEach(filteredCompletions) { location in
            Button(action: {
                switch UserDefaultsServices.shared.saveFavoriteLocationData(data: location) {
                case .success:
                    sheetEnvironment.refreshFavoriteLocations()
                    dismiss()
                case let .failure(error):
                    print(error)
                }
            }, label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(location.title)
                            .font(.headline)
                        Text(location.subTitle)
                    }.foregroundStyle(.foreground)

                    Spacer()

                    Image(systemName: "plus")
                }

            })
        }
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
                currentUserSection()
                searchedResultsSection()
            }
            .onChange(of: search) { _, searchValue in
                tripPlanner.updateQuery(queryFragment: searchValue)
            }
        }
    }
}

#Preview {
    AddFavoriteLocationsSheet()
        .environmentObject(PreviewHelpers.buildTripPlannerService())
}
