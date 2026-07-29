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

/// A stateful, cancellable pipeline from viewport updates to diffed rental snapshots.
///
/// The work between "user pans the map" and "annotations are correct" is the same for
/// every host and involves no MapKit: coalescing viewport changes, cancelling superseded
/// fetches, filtering by form factor, and reconciling against what was previously
/// delivered. This actor owns all of it; hosts apply the emitted diffs directly.
///
/// `snapshots` and `fetchFailures` are single-consumer streams: attach exactly one
/// iterator to each for the lifetime of the source.
public actor VehicleRentalSource {

    /// A failed fetch. Emitted on `fetchFailures` instead of the snapshot stream so a
    /// transient error never disturbs already-delivered map state. Hosts use the *first*
    /// failure to dim a layer row ("Not available right now") and any later success to
    /// un-dim it.
    public struct FetchFailure: Sendable {
        public let underlyingError: any Error
        public let occurredAt: Date

        /// Convenience for logging and rider-facing reasons.
        public var message: String { underlyingError.localizedDescription }
    }

    /// Snapshots delivered as the viewport or form-factor selection changes.
    public nonisolated let snapshots: AsyncStream<VehicleRentalSnapshot>

    /// Fetch failures (transport, HTTP, decode). Superseded and cancelled fetches
    /// are never reported.
    public nonisolated let fetchFailures: AsyncStream<FetchFailure>

    private let snapshotContinuation: AsyncStream<VehicleRentalSnapshot>.Continuation
    private let failureContinuation: AsyncStream<FetchFailure>.Continuation

    private let service: VehicleRentalService
    private let coalescingInterval: Duration
    private let boundingBoxPadding: Double

    private var formFactors: Set<VehicleFormFactor>?
    private var viewport: VehicleRentalBoundingBox?
    private var delivered: [VehicleRental.ID: VehicleRental] = [:]
    private var pendingFetch: Task<Void, Never>?

    /// Incremented whenever pending work becomes stale (new viewport, new filter,
    /// clear). A fetch only applies its result if its generation is still current —
    /// this covers the window where a task has passed its cancellation checks but
    /// not yet delivered.
    private var generation = 0

    /// - Parameters:
    ///   - service: The rental-capable backend, typically a `GraphQLAPIService`.
    ///   - formFactors: Initial form-factor filter; `nil` fetches everything.
    ///   - coalescingInterval: Trailing debounce applied to viewport/filter changes.
    ///     The 250 ms default matches OBA's established map debounce.
    ///   - boundingBoxPadding: Multiplier applied to the viewport before fetching, so
    ///     small pans are already covered. 1.1 mirrors OBA's region fudge factor.
    public init(
        service: VehicleRentalService,
        formFactors: Set<VehicleFormFactor>? = nil,
        coalescingInterval: Duration = .milliseconds(250),
        boundingBoxPadding: Double = 1.1
    ) {
        self.service = service
        self.formFactors = formFactors
        self.coalescingInterval = coalescingInterval
        self.boundingBoxPadding = boundingBoxPadding

        (snapshots, snapshotContinuation) = AsyncStream.makeStream(of: VehicleRentalSnapshot.self)
        (fetchFailures, failureContinuation) = AsyncStream.makeStream(of: FetchFailure.self)
    }

    deinit {
        pendingFetch?.cancel()
        snapshotContinuation.finish()
        failureContinuation.finish()
    }

    // MARK: - Inputs

    /// Called on every map region change. Coalesces; cancels superseded work.
    /// Passing `nil` (e.g. the zoom gate closed) immediately emits a snapshot
    /// removing everything.
    public func setViewport(_ boundingBox: VehicleRentalBoundingBox?) {
        guard let boundingBox else {
            clear()
            return
        }
        viewport = boundingBox
        scheduleFetch()
    }

    /// Changes what is being fetched without tearing down the stream. Triggers a
    /// refetch when a viewport is set.
    public func setFormFactors(_ formFactors: Set<VehicleFormFactor>?) {
        guard formFactors != self.formFactors else { return }
        self.formFactors = formFactors
        if viewport != nil {
            scheduleFetch()
        }
    }

    /// Clears all state (e.g. the layer was switched off) and emits a snapshot
    /// removing everything previously delivered.
    public func reset() {
        clear()
    }

    // MARK: - Pipeline

    private func clear() {
        pendingFetch?.cancel()
        pendingFetch = nil
        generation += 1
        viewport = nil

        let removed = delivered.keys.sorted()
        delivered = [:]
        snapshotContinuation.yield(VehicleRentalSnapshot(
            added: [],
            removed: removed,
            updated: [],
            fetchedAt: Date()
        ))
    }

    private func scheduleFetch() {
        pendingFetch?.cancel()
        generation += 1
        let scheduledGeneration = generation
        let interval = coalescingInterval

        // The task inherits the actor's isolation: the sleep and the fetch suspend
        // without blocking other actor work (fetchPlan on the same service is
        // unaffected — decode already runs off-actor in GraphQLAPIService).
        pendingFetch = Task {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            await self.performFetch(generation: scheduledGeneration)
        }
    }

    private func performFetch(generation scheduledGeneration: Int) async {
        guard scheduledGeneration == generation, let viewport else { return }
        let paddedBox = viewport.padded(by: boundingBoxPadding)

        do {
            let result = try await service.fetchVehicleRentals(in: paddedBox, formFactors: formFactors)
            guard scheduledGeneration == generation else { return }
            apply(result)
        } catch is CancellationError {
            // Superseded by a newer viewport; the newer fetch reports instead.
        } catch {
            guard scheduledGeneration == generation else { return }
            failureContinuation.yield(FetchFailure(underlyingError: error, occurredAt: Date()))
        }
    }

    /// Diffs the fetch result against what was previously delivered, keyed on
    /// `VehicleRental.id`. `added`/`updated` preserve response order; `removed` is
    /// sorted for determinism.
    private func apply(_ result: VehicleRentalFetchResult) {
        var added: [VehicleRental] = []
        var updated: [VehicleRental] = []
        var incoming: [VehicleRental.ID: VehicleRental] = [:]
        incoming.reserveCapacity(result.rentals.count)

        for rental in result.rentals {
            // Duplicate IDs in one payload: last write wins in state, first wins in the
            // delivered arrays (guarded by the incoming-dict check).
            guard incoming.updateValue(rental, forKey: rental.id) == nil else { continue }

            if let previous = delivered[rental.id] {
                if previous != rental {
                    updated.append(rental)
                }
            } else {
                added.append(rental)
            }
        }

        let removed = delivered.keys.filter { incoming[$0] == nil }.sorted()
        delivered = incoming

        snapshotContinuation.yield(VehicleRentalSnapshot(
            added: added,
            removed: removed,
            updated: updated,
            fetchedAt: Date(),
            partialErrors: result.partialErrors
        ))
    }
}

extension VehicleRentalBoundingBox {
    /// Expands the box around its center by the given factor, clamped to valid
    /// coordinate ranges. Does not handle antimeridian-spanning boxes.
    func padded(by factor: Double) -> VehicleRentalBoundingBox {
        guard factor != 1 else { return self }

        let latitudeCenter = (minimumLatitude + maximumLatitude) / 2
        let longitudeCenter = (minimumLongitude + maximumLongitude) / 2
        let latitudeHalfSpan = (maximumLatitude - minimumLatitude) / 2 * factor
        let longitudeHalfSpan = (maximumLongitude - minimumLongitude) / 2 * factor

        return VehicleRentalBoundingBox(
            minimumLatitude: max(-90, latitudeCenter - latitudeHalfSpan),
            maximumLatitude: min(90, latitudeCenter + latitudeHalfSpan),
            minimumLongitude: max(-180, longitudeCenter - longitudeHalfSpan),
            maximumLongitude: min(180, longitudeCenter + longitudeHalfSpan)
        )
    }
}
