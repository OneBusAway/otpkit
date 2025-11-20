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

        // Check if location already exists (by title and coordinates to avoid duplicates)
        let locationExists = locations.contains { existingLocation in
            existingLocation.title == data.title &&
            abs(existingLocation.latitude - data.latitude) < 0.0001 &&
            abs(existingLocation.longitude - data.longitude) < 0.0001
        }

        if locationExists {
            // Location already exists, no need to add again
            return .success(())
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
            let decodedSavedLocations = try decoder.decode(Set<Location>.self, from: savedLocationsData)
            let savedLocationsArray = decodedSavedLocations.sorted { $0.date > $1.date }
            return .success(savedLocationsArray)
        } catch {
            return .failure(error)
        }
    }

    func saveRecentLocations(data: Location) -> Result<Void, Error> {
        var locations: Set<Location> = switch getRecentLocations() {
        case let .success(existingLocations):
            Set(existingLocations)
        case .failure:
            []
        }

        locations.insert(data)

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(locations)
            userDefaults.set(encoded, forKey: recentLocationsKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Update Recent Location Date
    func updateRecentLocations(_ data: Location) -> Result<Void, Error> {
        var locations: Set<Location> = switch getRecentLocations() {
        case let .success(existingLocations):
            Set(existingLocations)
        case .failure:
            []
        }

        if var existingLocation = locations.first(where: { $0.id == data.id }) {
            existingLocation.date = Date()
            locations.update(with: existingLocation)
        }

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(locations)
            userDefaults.set(encoded, forKey: recentLocationsKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Delete Recent Location
    func deleteRecentLocation(with id: UUID) -> Result<Void, Error> {
        var locations: Set<Location>

        switch getRecentLocations() {
        case let .success(existingLocations):
            locations = Set(existingLocations)
        case let .failure(error):
            return .failure(error)
        }

        if let index = locations.firstIndex(where: { $0.id == id }) {
            locations.remove(at: index)
        }

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(locations)
            userDefaults.set(encoded, forKey: recentLocationsKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Trip Options Data

    private let wheelchairAccessibleKey = "OTPKit.TripOptions.wheelchairAccessible"
    private let maxWalkingDistanceKey = "OTPKit.TripOptions.maxWalkingDistance"
    private let routePreferenceKey = "OTPKit.TripOptions.routePreference"

    /// Loads saved trip options from UserDefaults
    /// Returns nil if no saved options exist
    func loadTripOptions() -> TripOptions? {
        // Check if any key exists, if not, return nil (first launch)
        guard userDefaults.object(forKey: wheelchairAccessibleKey) != nil ||
              userDefaults.object(forKey: maxWalkingDistanceKey) != nil ||
              userDefaults.object(forKey: routePreferenceKey) != nil else {
            return nil
        }

        let wheelchairAccessible = userDefaults.bool(forKey: wheelchairAccessibleKey)

        let walkingDistanceRawValue = userDefaults.integer(forKey: maxWalkingDistanceKey)
        let walkingDistance = WalkingDistance(rawValue: walkingDistanceRawValue) ?? .oneMile

        let routePreferenceRawValue = userDefaults.string(forKey: routePreferenceKey) ?? RoutePreference.fastestTrip.rawValue
        let routePreference = RoutePreference(rawValue: routePreferenceRawValue) ?? .fastestTrip

        return TripOptions(
            isWheelchairAccessible: wheelchairAccessible,
            maxWalkingDistance: walkingDistance,
            routePreference: routePreference
        )
    }

    /// Saves trip options to UserDefaults
    func saveTripOptions(_ options: TripOptions) {
        userDefaults.set(options.isWheelchairAccessible, forKey: wheelchairAccessibleKey)
        userDefaults.set(options.maxWalkingDistance.rawValue, forKey: maxWalkingDistanceKey)
        userDefaults.set(options.routePreference.rawValue, forKey: routePreferenceKey)
    }

    // MARK: - User Defaults Utils

    func deleteAllObjects() {
        userDefaults.removeObject(forKey: savedLocationsKey)
        userDefaults.removeObject(forKey: recentLocationsKey)
        userDefaults.removeObject(forKey: wheelchairAccessibleKey)
        userDefaults.removeObject(forKey: maxWalkingDistanceKey)
        userDefaults.removeObject(forKey: routePreferenceKey)
    }
}

// MARK: - Trip Options Model

/// Represents the persisted trip planning options.
/// These options are saved to UserDefaults and restored on app launch.
/// Time/date preferences are intentionally not persisted.
public struct TripOptions: Sendable {
    /// Whether routes should be wheelchair accessible
    public let isWheelchairAccessible: Bool

    /// Maximum walking distance for trip segments
    public let maxWalkingDistance: WalkingDistance

    /// Route optimization preference (fastest vs fewest transfers)
    public let routePreference: RoutePreference

    public init(
        isWheelchairAccessible: Bool,
        maxWalkingDistance: WalkingDistance,
        routePreference: RoutePreference
    ) {
        self.isWheelchairAccessible = isWheelchairAccessible
        self.maxWalkingDistance = maxWalkingDistance
        self.routePreference = routePreference
    }
}
