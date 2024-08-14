//
//  UserDefaultsServices.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation

/// Manages data persistance
/// Each CRUD features divided by `MARK` comment
public final class UserDefaultsServices {
    public static let shared = UserDefaultsServices()
    private let userDefaults = UserDefaults.standard
    private let savedLocationsKey = "SavedLocations"
    private let recentLocationsKey = "RecentLocations"

    // MARK: - Saved Location Data

    func getFavoriteLocationsData() -> Result<[Location], Error> {
        guard let savedLocationsData = userDefaults.data(forKey: savedLocationsKey) else {
            let error = NSError(domain: "UserDefaults",
                                code: 1001,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve saved locations data"])
            return .failure(error)
        }

        let decoder = JSONDecoder()
        do {
            let decodedSavedLocations = try decoder.decode([Location].self, from: savedLocationsData)
            return .success(decodedSavedLocations)
        } catch {
            return .failure(error)
        }
    }

    func saveFavoriteLocationData(data: Location) -> Result<Void, Error> {
        var locations: [Location] = switch getFavoriteLocationsData() {
        case let .success(existingLocations):
            existingLocations
        case .failure:
            []
        }

        locations.append(data)

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(locations)
            userDefaults.set(encoded, forKey: savedLocationsKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func deleteFavoriteLocationData(with id: UUID) -> Result<Void, Error> {
        var locations: [Location]

        switch getFavoriteLocationsData() {
        case let .success(existingLocations):
            locations = existingLocations
        case let .failure(error):
            return .failure(error)
        }

        locations.removeAll { $0.id == id }

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(locations)
            userDefaults.set(encoded, forKey: savedLocationsKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Recent Location Data

    func getRecentLocations() -> Result<[Location], Error> {
        guard let savedLocationsData = userDefaults.data(forKey: recentLocationsKey) else {
            let error = NSError(domain: "UserDefaults",
                                code: 1001,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve saved locations data"])
            return .failure(error)
        }

        let decoder = JSONDecoder()
        do {
            let decodedSavedLocations = try decoder.decode([Location].self, from: savedLocationsData)
            return .success(decodedSavedLocations)
        } catch {
            return .failure(error)
        }
    }

    func saveRecentLocations(data: Location) -> Result<Void, Error> {
        var locations: [Location] = switch getFavoriteLocationsData() {
        case let .success(existingLocations):
            existingLocations
        case .failure:
            []
        }

        locations.insert(data, at: 0)

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(locations)
            userDefaults.set(encoded, forKey: recentLocationsKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - User Defaults Utils

    func deleteAllObjects() {
        userDefaults.removeObject(forKey: savedLocationsKey)
        userDefaults.removeObject(forKey: recentLocationsKey)
    }
}
