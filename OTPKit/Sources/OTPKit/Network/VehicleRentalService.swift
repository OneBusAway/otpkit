/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// The capability to fetch vehicle rental (bikeshare/micromobility) data.
///
/// Separate from `APIService` because not every backend supports rentals —
/// `RestAPIService` (OTP 1.x) does not. Conformance doubles as the capability
/// flag: hosts check `apiService is VehicleRentalService` to decide whether
/// rental features can work at all.
///
/// `Sendable` because services are shared across isolation domains by design:
/// `VehicleRentalSource` (an actor) fetches through one while hosts hold it on
/// the main actor. Conformers are typically actors already.
public protocol VehicleRentalService: Sendable {
    /// Fetches rental stations and free-floating vehicles in a bounding box.
    ///
    /// - Parameters:
    ///   - boundingBox: The geographic area to search. Keep it small: the OTP
    ///     `vehicleRentalsByBbox` query has no server-side result limit, and a
    ///     metro-sized box can return over 12,000 entities.
    ///   - formFactors: When non-nil, only entities matching these form factors
    ///     are returned. Entities without typed form-factor data are included
    ///     (fail-open) so sparse feeds don't disappear.
    func fetchVehicleRentals(
        in boundingBox: VehicleRentalBoundingBox,
        formFactors: Set<VehicleFormFactor>?
    ) async throws -> VehicleRentalFetchResult
}
