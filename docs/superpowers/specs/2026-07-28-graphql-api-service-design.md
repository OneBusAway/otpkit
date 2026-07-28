# OTP 2.x GraphQL Support — Design

**Date:** 2026-07-28
**Goal:** OTPKit works against both OTP 1.x (REST) and OTP 2.x (GraphQL) servers, side by side. No feature expansion — the GraphQL path supports exactly what the REST path supports today.

## Background

OTPKit already isolates networking behind the `APIService` protocol (`fetchPlan(_:) async throws -> OTPResponse`), which was explicitly designed for plugin backends. `RestAPIService` is the only implementation. OTP 2.x servers expose the GTFS GraphQL API at `<server>/otp/gtfs/v1`.

Verified against the target server (`https://sound-transit-otp.ibi-transit.com/otp/`, OTP 2.10.0-SNAPSHOT):

- The GraphQL `plan` query works and returns a shape nearly identical to the OTP 1.x REST response: itineraries/legs with epoch-millisecond timestamps, `legGeometry.points` polylines, `intermediatePlaces`, `steps`.
- It accepts the same wire formats OTPKit already emits for REST (`date: "MM-dd-yyyy"`, `time: "h:mm a"`), plus `maxWalkDistance`, `arriveBy`, `wheelchair`, and `transportModes`.
- Routing failures come back as `routingErrors` (codes like `OUTSIDE_BOUNDS`, `NO_TRANSIT_CONNECTION`) instead of the REST `error` object.
- Nested objects differ from REST: route info lives in `route { shortName type color textColor agency { name } }` and stop IDs in `from.stop { gtfsId code }`.

## Approaches considered

1. **Hand-rolled query + internal Codable DTOs, mapped to existing public models (chosen).** One static GraphQL document, a `variables` dictionary, a small internal DTO tree, and a mapping layer that produces the same `OTPResponse` the REST service produces. No new dependencies; the rest of the app is untouched.
2. **Apollo iOS with codegen.** Type-safe, but adds a heavyweight dependency and codegen toolchain for a single query. Rejected as overkill.
3. **Decode GraphQL JSON directly into the existing public models.** The nesting differences (route/agency/stop) would force custom decoding logic into public model types serving two wire formats at once. Rejected as fragile.

Query choice: the legacy `plan` query rather than `planConnection`. `plan` maps 1:1 onto OTPKit's existing models and exists in every OTP 2.x release (verified working on 2.10). `planConnection` is the long-term replacement but has a substantially different shape (cursor connections, `OffsetDateTime` strings, `LegTime` objects) — migrating to it is future work and is contained entirely within `GraphQLAPIService` when it happens.

## Design

### New: `GraphQLAPIService` (OTPKit/Sources/OTPKit/Network/GraphQLAPIService.swift)

A `public actor GraphQLAPIService: APIService`, mirroring `RestAPIService`:

- `init(baseURL: URL, dataLoader: URLDataLoader = URLSession.shared)`
- Base URL normalization: strip a trailing `routers/<id>` segment if present (so REST-style URLs still work), then append `gtfs/v1` unless the path already ends with it. `https://…/otp/` → `https://…/otp/gtfs/v1`.
- `fetchPlan(_ request: TripPlanRequest)` POSTs `{"query": …, "variables": …}` with `Content-Type: application/json`, using the same `URLDataLoader` abstraction and the existing wire-format date/time formatters.
- Non-200 responses throw `OTPKitError.apiError`, same as REST. Top-level GraphQL `errors` throw `OTPKitError.apiError` with the first error message.

### New: internal wire DTOs (OTPKit/Sources/OTPKit/Network/GraphQLPlanResponse.swift)

Internal `Decodable` structs matching the GraphQL response (`plan.itineraries[].legs[].route.agency` etc.), decoded with `.millisecondsSince1970` dates, then mapped to the existing public models:

| Public model field | GraphQL source |
|---|---|
| `Itinerary.transitTime` | computed: `max(0, duration - walkTime - waitingTime)` |
| `Itinerary.transfers` | `numberOfTransfers` |
| `Itinerary.walkLimitExceeded` | constant `false` (OTP 2.x removed the hard limit) |
| `Leg.route` / `routeType` / `routeColor` / `routeTextColor` / `agencyName` | `route.shortName` / `route.type` / `route.color` / `route.textColor` / `route.agency.name` |
| `Place.stopId` / `stopCode` | `stop.gtfsId` / `stop.code` |
| `Leg.intermediateStops` | `intermediatePlaces` |
| `OTPResponse.requestParameters` | synthesized from the outgoing `TripPlanRequest` (same strings REST would send) |
| `OTPResponse.error` | first `routingError`, only when no itineraries came back |

Routing-error code mapping (default `.unknown`): `OUTSIDE_BOUNDS → .outsideBounds`, `NO_TRANSIT_CONNECTION → .pathNotFound`, `NO_TRANSIT_CONNECTION_IN_SEARCH_WINDOW`/`OUTSIDE_SERVICE_PERIOD → .noTransitTimes`, `LOCATION_NOT_FOUND`/`NO_STOPS_IN_RANGE → .locationNotAccessible`, `WALKING_BETTER_THAN_TRANSIT` is ignored (not a failure).

`Leg.streetNames` and `Leg.pathway` have no GraphQL equivalent and are `nil` (both already optional and unused by the UI).

### Demo app

`OTPRegionInfo` gains an `apiType` field (`rest` | `graphQL`, defaulting to `rest` when absent so persisted regions still decode). The onboarding list adds "Seattle (OTP 2.x GraphQL)" pointing at `https://sound-transit-otp.ibi-transit.com/otp/`. `OTPDemoViewController.apiService` becomes `APIService` and is constructed per the region's `apiType`.

### Error handling

- Transport/HTTP failures: `OTPKitError.apiError` (unchanged behavior).
- GraphQL validation errors (top-level `errors` array): `OTPKitError.apiError` with the server's message.
- Routing errors: surfaced through the existing `OTPResponse.error` → `ErrorResponseCode.displayMessage` path, so `TripPlannerViewModel` needs no changes.

### Testing

XCTest in the package test target, mirroring `RestAPIServiceTests`:

- Fixtures captured from the live Sound Transit server: success response and routing-error response.
- Request-building tests: endpoint URL normalization (all three input shapes), POST body contains expected variables (coordinates, modes, arriveBy, wheelchair, maxWalkDistance, date/time strings).
- Decoding/mapping tests: itinerary counts, timestamps, leg route/agency/stop mapping, transitTime computation, routing-error → `ErrorResponse` mapping, top-level GraphQL error → thrown `OTPKitError`.
- Manual end-to-end verification against the live server via the demo app.
