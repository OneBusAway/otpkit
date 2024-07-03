import Foundation

final actor UserDefaultsServices {
    static let shared = UserDefaultsServices()
    private let userDefaults = UserDefaults.standard
    private let savedLocationsKey = "SavedLocations"

    // MARK: - Saved Location Data

    func getLocationsData() -> Result<[SavedLocation], Error> {
        guard let savedLocationsData = userDefaults.data(forKey: savedLocationsKey) else {
            return .success([])
        }

        let decoder = JSONDecoder()
        do {
            let decodedSavedLocations = try decoder.decode([SavedLocation].self, from: savedLocationsData)
            return .success(decodedSavedLocations)
        } catch {
            return .failure(error)
        }
    }

    func saveLocationData(data: SavedLocation) -> Result<Void, Error> {
        var locations: [SavedLocation]

        switch getLocationsData() {
        case let .success(existingLocations):
            locations = existingLocations
        case let .failure(error):
            return .failure(error)
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

    func deleteLocationData(with id: UUID) -> Result<Void, Error> {
        var locations: [SavedLocation]

        switch getLocationsData() {
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
}
