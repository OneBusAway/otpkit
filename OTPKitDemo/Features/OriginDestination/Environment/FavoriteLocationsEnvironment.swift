//
//  FavoriteLocationsEnvironment.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation

class FavoriteLocationsEnvironment: ObservableObject {
    @Published var favoriteLocations: [Location] = []

    func refreshFavoriteLocations() {
        switch UserDefaultsServices.shared.getFavoriteLocationsData() {
        case let .success(locations):
            favoriteLocations = locations
        case let .failure(error):
            print("Failed to refresh favorite locations: \(error)")
            // Handle the error appropriately
        }
    }
}
