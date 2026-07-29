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

/// The result of a rental fetch.
///
/// GraphQL responses can carry both `data` and `errors` (partial success). A throwing
/// `[VehicleRental]` return couldn't convey that, so the result carries the usable
/// entities alongside any non-fatal error messages — a half-populated map beats an
/// error state for a browse layer.
public struct VehicleRentalFetchResult: Sendable {
    public let rentals: [VehicleRental]
    /// Non-fatal GraphQL error messages that accompanied partial data. Empty on full success.
    public let partialErrors: [String]

    public init(rentals: [VehicleRental], partialErrors: [String] = []) {
        self.rentals = rentals
        self.partialErrors = partialErrors
    }
}
