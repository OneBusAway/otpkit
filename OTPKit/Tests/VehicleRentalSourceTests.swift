//
//  VehicleRentalSourceTests.swift
//  OTPKitTests
//
//  Tests for the stateful viewport→snapshot rental pipeline: coalescing,
//  cancellation, diffing, clearing, and failure reporting.
//

import Foundation
import Testing
@testable import OTPKit

/// One recorded `fetchVehicleRentals` invocation on the scripted service.
private struct RentalServiceCall: Sendable {
    let boundingBox: VehicleRentalBoundingBox
    let formFactors: Set<VehicleFormFactor>?
}

/// Thrown when `waitForCalls` gives up, so a source that stops issuing fetches
/// fails the test with a readable message instead of suspending until xcodebuild
/// kills the run.
private struct CallWaitTimeout: Error, CustomStringConvertible {
    let expected: Int
    let observed: Int
    var description: String {
        "waitForCalls timed out waiting for \(expected) fetch(es); observed \(observed)"
    }
}

@Suite("VehicleRentalSource")
struct VehicleRentalSourceTests {

    // MARK: - Scripted service

    private actor ScriptedRentalService: VehicleRentalService {
        private(set) var calls: [RentalServiceCall] = []
        private var results: [Result<VehicleRentalFetchResult, Error>]
        private var delay: Duration = .zero
        private var callCountWaiters: [UUID: (threshold: Int, continuation: CheckedContinuation<Void, Error>)] = [:]

        init(results: [Result<VehicleRentalFetchResult, Error>]) {
            self.results = results
        }

        func setDelay(_ delay: Duration) {
            self.delay = delay
        }

        /// Suspends until at least `count` fetches have started. Tests that need a
        /// fetch to be genuinely in flight wait on this rather than sleeping for a
        /// fraction of `delay`: a contended CI runner can overrun any such sleep,
        /// which makes the assertion race the scheduler instead of testing the source.
        ///
        /// The deadline is a backstop, not a timing assumption — it is far longer
        /// than any healthy fetch needs, and exists only so a regression surfaces as
        /// a failed expectation rather than a hung job.
        func waitForCalls(_ count: Int, timeout: Duration = .seconds(10)) async throws {
            guard calls.count < count else { return }

            let id = UUID()
            let timeoutTask = Task { [weak self] in
                // A thrown sleep means the wait already finished and cancelled us.
                do { try await Task.sleep(for: timeout) } catch { return }
                await self?.timeOutWaiter(id, expected: count)
            }
            defer { timeoutTask.cancel() }

            try await withCheckedThrowingContinuation { continuation in
                callCountWaiters[id] = (count, continuation)
            }
        }

        private func notifyCallCountWaiters() {
            // Removing before resuming keeps a continuation from being resumed
            // twice, which would trap. Iteration is over a copy, so mutating the
            // dictionary inside the loop is safe.
            for (id, waiter) in callCountWaiters where calls.count >= waiter.threshold {
                callCountWaiters.removeValue(forKey: id)
                waiter.continuation.resume()
            }
        }

        private func timeOutWaiter(_ id: UUID, expected: Int) {
            guard let waiter = callCountWaiters.removeValue(forKey: id) else { return }
            waiter.continuation.resume(
                throwing: CallWaitTimeout(expected: expected, observed: calls.count)
            )
        }

        func fetchVehicleRentals(
            in boundingBox: VehicleRentalBoundingBox,
            formFactors: Set<VehicleFormFactor>?
        ) async throws -> VehicleRentalFetchResult {
            calls.append(RentalServiceCall(boundingBox: boundingBox, formFactors: formFactors))
            notifyCallCountWaiters()

            // Claim the scripted result at call time, before any delay: a cancelled
            // call must still consume its result so later calls stay aligned with
            // the script. The last result is sticky so repeated fetches keep working.
            let result: Result<VehicleRentalFetchResult, Error>
            if results.isEmpty {
                result = .success(VehicleRentalFetchResult(rentals: []))
            } else if results.count == 1 {
                result = results[0]
            } else {
                result = results.removeFirst()
            }

            if delay > .zero {
                try await Task.sleep(for: delay)
            }
            return try result.get()
        }
    }

    private struct ScriptedError: Error {}

    // MARK: - Fixtures

    private static let seattleBox = VehicleRentalBoundingBox(
        minimumLatitude: 47.5,
        maximumLatitude: 47.7,
        minimumLongitude: -122.4,
        maximumLongitude: -122.2
    )

    /// A slightly panned viewport: identical boxes are deliberately deduplicated
    /// by the source, so successive fetches in tests must actually move.
    private static func pannedBox(_ offset: Double) -> VehicleRentalBoundingBox {
        VehicleRentalBoundingBox(
            minimumLatitude: 47.5 + offset,
            maximumLatitude: 47.7 + offset,
            minimumLongitude: -122.4,
            maximumLongitude: -122.2
        )
    }

    private static func makeRental(id: String, lat: Double = 47.61) -> VehicleRental {
        .vehicle(RentalVehicle(
            vehicleId: id,
            name: "Default vehicle type",
            lat: lat,
            lon: -122.33,
            allowPickupNow: true,
            operative: true,
            rentalNetwork: RentalNetwork(networkId: "lime_seattle", url: nil),
            rentalUris: nil,
            vehicleType: VehicleType(formFactor: .bicycle, propulsionType: "ELECTRIC_ASSIST"),
            fuel: nil
        ))
    }

    private static func makeSource(
        service: ScriptedRentalService,
        formFactors: Set<VehicleFormFactor>? = nil,
        coalescingInterval: Duration = .milliseconds(1),
        boundingBoxPadding: Double = 1.0
    ) -> VehicleRentalSource {
        VehicleRentalSource(
            service: service,
            formFactors: formFactors,
            coalescingInterval: coalescingInterval,
            boundingBoxPadding: boundingBoxPadding
        )
    }

    // MARK: - Tests

    @Test("First fetch delivers everything as added")
    func firstFetchAddsEverything() async throws {
        let rentals = [Self.makeRental(id: "a"), Self.makeRental(id: "b")]
        let service = ScriptedRentalService(results: [.success(VehicleRentalFetchResult(rentals: rentals))])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)

        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.added.map(\.id) == ["a", "b"])
        #expect(snapshot.removed.isEmpty)
        #expect(snapshot.updated.isEmpty)
        #expect(snapshot.partialErrors.isEmpty)
    }

    @Test("Successive fetches deliver an id-keyed diff")
    func diffAcrossViewports() async throws {
        let first = [Self.makeRental(id: "a"), Self.makeRental(id: "b")]
        let second = [Self.makeRental(id: "b", lat: 47.62), Self.makeRental(id: "c")]
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: first)),
            .success(VehicleRentalFetchResult(rentals: second))
        ])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setViewport(Self.pannedBox(0.01))
        let snapshot = try #require(await snapshots.next())

        #expect(snapshot.added.map(\.id) == ["c"])
        #expect(snapshot.removed == ["a"])
        #expect(snapshot.updated.map(\.id) == ["b"])
    }

    @Test("An identical viewport does not refetch")
    func identicalViewportDeduplicated() async throws {
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: [Self.makeRental(id: "a")]))
        ])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setViewport(Self.seattleBox)
        try await Task.sleep(for: .milliseconds(30))
        #expect(await service.calls.count == 1)
    }

    @Test("An unchanged entity is neither added nor updated")
    func unchangedEntityNotRedelivered() async throws {
        let rentals = [Self.makeRental(id: "a")]
        let service = ScriptedRentalService(results: [.success(VehicleRentalFetchResult(rentals: rentals))])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setViewport(Self.pannedBox(0.01))
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.isEmpty)
    }

    @Test("Rapid viewport changes coalesce into one fetch")
    func coalescesViewportChanges() async throws {
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: [Self.makeRental(id: "a")]))
        ])
        let source = Self.makeSource(service: service, coalescingInterval: .milliseconds(100))
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(VehicleRentalBoundingBox(
            minimumLatitude: 40, maximumLatitude: 41, minimumLongitude: -100, maximumLongitude: -99
        ))
        await source.setViewport(VehicleRentalBoundingBox(
            minimumLatitude: 41, maximumLatitude: 42, minimumLongitude: -101, maximumLongitude: -100
        ))
        await source.setViewport(Self.seattleBox)

        _ = try #require(await snapshots.next())

        let calls = await service.calls
        #expect(calls.count == 1)
        #expect(calls.first?.boundingBox == Self.seattleBox)
    }

    @Test("A superseded in-flight fetch is cancelled, not reported as a failure")
    func supersededFetchIsCancelled() async throws {
        let first = [Self.makeRental(id: "stale")]
        let second = [Self.makeRental(id: "fresh")]
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: first)),
            .success(VehicleRentalFetchResult(rentals: second))
        ])
        // Long enough that the first fetch can only ever leave this sleep by being
        // cancelled, so the test never depends on how fast the runner is.
        await service.setDelay(.seconds(30))
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        let failures = Box()
        let failureWatcher = Task {
            for await failure in source.fetchFailures {
                await failures.append(failure.message)
            }
        }

        await source.setViewport(Self.seattleBox)
        try await service.waitForCalls(1)  // the first fetch is now in flight and parked
        await service.setDelay(.zero)  // so the superseding fetch can complete
        await source.setViewport(Self.pannedBox(0.01))

        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.added.map(\.id) == ["fresh"])
        #expect(await service.calls.count == 2)

        try await Task.sleep(for: .milliseconds(50))
        #expect(await failures.values.isEmpty)
        failureWatcher.cancel()
    }

    @Test("A nil viewport clears everything immediately")
    func nilViewportClears() async throws {
        let rentals = [Self.makeRental(id: "a"), Self.makeRental(id: "b")]
        let service = ScriptedRentalService(results: [.success(VehicleRentalFetchResult(rentals: rentals))])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setViewport(nil)
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.added.isEmpty)
        #expect(snapshot.removed == ["a", "b"])
        #expect(await service.calls.count == 1)
    }

    @Test("reset() clears state and emits a removal snapshot")
    func resetClears() async throws {
        let rentals = [Self.makeRental(id: "a")]
        let service = ScriptedRentalService(results: [.success(VehicleRentalFetchResult(rentals: rentals))])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.reset()
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.removed == ["a"])
    }

    @Test("Partial GraphQL errors ride along on the snapshot")
    func partialErrorsForwarded() async throws {
        let result = VehicleRentalFetchResult(
            rentals: [Self.makeRental(id: "a")],
            partialErrors: ["feed lime_tacoma unavailable"]
        )
        let service = ScriptedRentalService(results: [.success(result)])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.partialErrors == ["feed lime_tacoma unavailable"])
    }

    @Test("A failed fetch reports on fetchFailures and preserves delivered state")
    func failureReported() async throws {
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: [Self.makeRental(id: "a")])),
            .failure(ScriptedError()),
            // The script's last result is sticky, so the recovery fetch below needs
            // its own success entry — otherwise the failure repeats forever and the
            // snapshot this test waits on is never emitted.
            .success(VehicleRentalFetchResult(rentals: [Self.makeRental(id: "a")]))
        ])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()
        var failures = source.fetchFailures.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setViewport(Self.pannedBox(0.01))
        let failure = try #require(await failures.next())
        #expect(failure.underlyingError is ScriptedError)

        // The next successful fetch diffs against state that survived the failure.
        await source.setViewport(Self.pannedBox(0.02))
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.isEmpty)
    }

    @Test("A failed viewport retries on the next identical region emission")
    func failedViewportRetries() async throws {
        let service = ScriptedRentalService(results: [
            .failure(ScriptedError()),
            .success(VehicleRentalFetchResult(rentals: [Self.makeRental(id: "a")]))
        ])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()
        var failures = source.fetchFailures.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = try #require(await failures.next())

        // A stationary map re-emits the same region; the failure must not be
        // swallowed by the same-viewport deduplication.
        await source.setViewport(Self.seattleBox)
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.added.map(\.id) == ["a"])
        #expect(await service.calls.count == 2)
    }

    @Test("Changing form factors refetches with the new filter")
    func formFactorChangeRefetches() async throws {
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: [Self.makeRental(id: "a")]))
        ])
        let source = Self.makeSource(service: service, formFactors: [.bicycle])
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setFormFactors([.bicycle, .scooter])
        _ = await snapshots.next()

        let calls = await service.calls
        #expect(calls.count == 2)
        #expect(calls[0].formFactors == [.bicycle])
        #expect(calls[1].formFactors == [.bicycle, .scooter])
    }

    @Test("Setting the same form factors does not refetch")
    func sameFormFactorsNoRefetch() async throws {
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: []))
        ])
        let source = Self.makeSource(service: service, formFactors: [.bicycle])
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        _ = await snapshots.next()

        await source.setFormFactors([.bicycle])
        try await Task.sleep(for: .milliseconds(30))
        #expect(await service.calls.count == 1)
    }

    @Test("The viewport is padded before fetching")
    func paddingApplied() async throws {
        let service = ScriptedRentalService(results: [
            .success(VehicleRentalFetchResult(rentals: []))
        ])
        let source = Self.makeSource(service: service, boundingBoxPadding: 2.0)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(VehicleRentalBoundingBox(
            minimumLatitude: 47.0, maximumLatitude: 48.0, minimumLongitude: -122.0, maximumLongitude: -121.0
        ))
        _ = await snapshots.next()

        let box = try #require(await service.calls.first?.boundingBox)
        #expect(abs(box.minimumLatitude - 46.5) < 0.0001)
        #expect(abs(box.maximumLatitude - 48.5) < 0.0001)
        #expect(abs(box.minimumLongitude - (-122.5)) < 0.0001)
        #expect(abs(box.maximumLongitude - (-120.5)) < 0.0001)
    }

    @Test("Duplicate ids in one payload are delivered once")
    func duplicateIdsDeliveredOnce() async throws {
        let rentals = [Self.makeRental(id: "a"), Self.makeRental(id: "a", lat: 47.62)]
        let service = ScriptedRentalService(results: [.success(VehicleRentalFetchResult(rentals: rentals))])
        let source = Self.makeSource(service: service)
        var snapshots = source.snapshots.makeAsyncIterator()

        await source.setViewport(Self.seattleBox)
        let snapshot = try #require(await snapshots.next())
        #expect(snapshot.added.map(\.id) == ["a"])
    }

    // MARK: - Helpers

    private actor Box {
        private(set) var values: [String] = []
        func append(_ value: String) { values.append(value) }
    }
}
