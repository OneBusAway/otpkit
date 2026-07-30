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

/// A diffed set of rental entities delivered by `VehicleRentalSource` as the
/// viewport changes. Consumers apply the diff directly — no reconciliation
/// against previously delivered state is needed.
public struct VehicleRentalSnapshot: Sendable {
    /// Entities that were not present in the previous snapshot.
    public let added: [VehicleRental]

    /// IDs of entities present in the previous snapshot but gone now.
    public let removed: [VehicleRental.ID]

    /// Entities whose data changed since the previous snapshot (position,
    /// availability, fuel, operative state). Updating these in place — rather
    /// than remove/re-add — preserves a selected callout across refreshes.
    public let updated: [VehicleRental]

    public let fetchedAt: Date

    /// Non-fatal GraphQL error messages that accompanied partial data.
    /// Empty on full success.
    public let partialErrors: [String]

    public init(
        added: [VehicleRental],
        removed: [VehicleRental.ID],
        updated: [VehicleRental],
        fetchedAt: Date,
        partialErrors: [String] = []
    ) {
        self.added = added
        self.removed = removed
        self.updated = updated
        self.fetchedAt = fetchedAt
        self.partialErrors = partialErrors
    }

    /// True when the snapshot changes nothing (no adds, removals, or updates).
    public var isEmpty: Bool {
        added.isEmpty && removed.isEmpty && updated.isEmpty
    }
}
