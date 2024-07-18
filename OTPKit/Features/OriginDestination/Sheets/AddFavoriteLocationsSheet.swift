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

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment

    @State private var search = ""
    private let userLocation = UserLocationServices.shared.currentLocation

    @FocusState private var isSearchActive: Bool

    private var filteredCompletions: [Location] {
        let favorites = sheetEnvironment.favoriteLocations
        return locationService.completions.filter { completion in
            !favorites.contains { favorite in
                favorite.title == completion.title &&
                    favorite.subTitle == completion.subTitle
            }
        }
    }

    public var body: some View {
        VStack {
            HStack {
                Text("Add favorite location")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                })
            }
            .padding()

            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a place", text: $search)
                    .autocorrectionDisabled()
                    .focused($isSearchActive)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.2))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)

            List {
                if search.isEmpty, let userLocation {
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
                }

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
            .onChange(of: search) { _, searchValue in
                locationService.update(queryFragment: searchValue)
            }
        }
    }
}

#Preview {
    AddFavoriteLocationsSheet()
}
