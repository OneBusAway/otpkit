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

    @ObservedObject private var locationManagerService = LocationManagerService.shared

    @State private var search = ""

    @FocusState private var isSearchFocused: Bool

    private var filteredCompletions: [Location] {
        let favorites = sheetEnvironment.favoriteLocations
        return locationManagerService.completions.filter { completion in
            !favorites.contains { favorite in
                favorite.title == completion.title &&
                    favorite.subTitle == completion.subTitle
            }
        }
    }

    private func searchView() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search for a place", text: $search)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func currentUserSection() -> some View {
        if search.isEmpty, let userLocation = locationManagerService.currentLocation {
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
                        }.foregroundStyle(Color.black)

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
                    }.foregroundStyle(Color.black)

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
            searchView()
            List {
                currentUserSection()
                searchedResultsSection()
            }
            .onChange(of: search) { _, searchValue in
                locationManagerService.updateQuery(queryFragment: searchValue)
            }
        }
    }
}

#Preview {
    AddFavoriteLocationsSheet()
}
