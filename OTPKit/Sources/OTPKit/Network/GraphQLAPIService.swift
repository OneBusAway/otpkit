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
import OSLog

/// Actor-based GraphQL API client for OTP 2.x trip planning and vehicle rentals
/// via the GTFS GraphQL API.
///
/// Most of the type body is the two static GraphQL documents; the lint pragmas
/// below account for them, not for logic.
public actor GraphQLAPIService: APIService, VehicleRentalService { // swiftlint:disable:this type_body_length
    public nonisolated let baseURL: URL
    public nonisolated let dataLoader: URLDataLoader

    /// The GraphQL endpoint the service POSTs to, derived from `baseURL`.
    public nonisolated let endpointURL: URL

    /// Creates a GraphQL API client
    /// - Parameters:
    ///   - baseURL: Base URL of the OTP server, e.g. `https://otp.example.com/otp/`
    ///   - dataLoader: Network loader (defaults to `URLSession.shared`)
    public init(
        baseURL: URL,
        dataLoader: URLDataLoader = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.dataLoader = dataLoader
        self.endpointURL = Self.normalizeEndpointURL(baseURL)
    }

    /// Fetches a trip plan using a `TripPlanRequest`
    public func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
        let urlRequest = try makeGraphQLRequest(
            query: Self.planQuery(includingVia: request.viaPoint != nil),
            variables: Self.planVariables(for: request)
        )

        Logger.main.info("Fetching trip plan via GraphQL: \(self.endpointURL.absoluteString)")

        let data = try await dataLoader.validatedData(for: urlRequest)
        let envelope = try JSONDecoder.otpDecoder().decode(GraphQLEnvelope<GraphQLPlanData>.self, from: data)

        if let firstError = envelope.errors?.first {
            throw OTPKitError.apiError(firstError.message)
        }

        guard let plan = envelope.data?.plan else {
            throw OTPKitError.invalidResponse()
        }

        return OTPResponse(
            requestParameters: Self.requestParameters(for: request),
            plan: plan.toPlan(),
            error: plan.toErrorResponse()
        )
    }

    // MARK: - Vehicle Rentals

    /// Fetches rental stations and free-floating vehicles in a bounding box.
    ///
    /// Unlike `fetchPlan`, this tolerates GraphQL partial success: a response carrying
    /// both data and errors returns the data, with the error messages surfaced in
    /// `VehicleRentalFetchResult.partialErrors`. Unrecognized `RentalPlace` union
    /// members are skipped (and logged), not treated as a failed fetch.
    public func fetchVehicleRentals(
        in boundingBox: VehicleRentalBoundingBox,
        formFactors: Set<VehicleFormFactor>?
    ) async throws -> VehicleRentalFetchResult {
        let urlRequest = try makeGraphQLRequest(
            query: Self.rentalsQuery,
            variables: [
                "minLat": boundingBox.minimumLatitude,
                "maxLat": boundingBox.maximumLatitude,
                "minLon": boundingBox.minimumLongitude,
                "maxLon": boundingBox.maximumLongitude
            ]
        )

        Logger.main.info("Fetching vehicle rentals via GraphQL: \(self.endpointURL.absoluteString)")

        let data = try await dataLoader.validatedData(for: urlRequest)
        return try await Self.decodeRentals(data, formFactors: formFactors)
    }

    /// Decodes and filters a rentals payload. Nonisolated *async* so it hops to the
    /// global concurrent executor — a multi-thousand-entity decode must never hold the
    /// actor and serialize a concurrent `fetchPlan` behind it.
    private nonisolated static func decodeRentals(
        _ data: Data,
        formFactors: Set<VehicleFormFactor>?
    ) async throws -> VehicleRentalFetchResult {
        let envelope = try JSONDecoder.otpDecoder().decode(GraphQLEnvelope<GraphQLRentalsData>.self, from: data)

        guard let payload = envelope.data, payload.vehicleRentalsByBbox != nil else {
            if let firstError = envelope.errors?.first {
                throw OTPKitError.apiError(firstError.message)
            }
            throw OTPKitError.invalidResponse()
        }
        let rentals = payload.rentals

        let filtered: [VehicleRental]
        if let formFactors {
            filtered = rentals.filter { $0.matches(formFactors: formFactors) }
        } else {
            filtered = rentals
        }

        return VehicleRentalFetchResult(
            rentals: filtered,
            partialErrors: envelope.errors?.map(\.message) ?? []
        )
    }

    // MARK: - Request Building

    /// Assembles the POST request shared by every GraphQL operation.
    private func makeGraphQLRequest(query: String, variables: [String: Any]) throws -> URLRequest {
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query,
            "variables": variables
        ])
        return urlRequest
    }

    /// Builds the GraphQL `variables` payload for a trip plan request.
    private static func planVariables(for request: TripPlanRequest) -> [String: Any] {
        var variables: [String: Any] = [
            "from": ["lat": request.origin.latitude, "lon": request.origin.longitude],
            "to": ["lat": request.destination.latitude, "lon": request.destination.longitude],
            "date": request.date.formattedTripDate,
            "time": request.time.formattedTripTime,
            "transportModes": request.wireTransportModes.map { graphQLTransportMode(for: $0) },
            "arriveBy": request.arriveBy,
            "wheelchair": request.wheelchairAccessible,
            "maxWalkDistance": Double(request.maxWalkDistance)
        ]

        // Omitted entirely when absent: a null `via` and a missing `via` are not
        // guaranteed to be treated identically by every OTP build.
        if let viaPoint = request.viaPoint {
            variables["via"] = [
                ["visit": ["coordinate": ["latitude": viaPoint.latitude, "longitude": viaPoint.longitude]]]
            ]
        }

        return variables
    }

    /// The GraphQL `TransportMode` input value for a transport mode. `TransportMode.rawValue`
    /// is the OTP 1.x REST token, which mostly — but not always — matches the GraphQL
    /// vocabulary; rentals additionally need the `RENT` qualifier.
    private static func graphQLTransportMode(for mode: TransportMode) -> [String: String] {
        switch mode {
        case .bike:
            return ["mode": "BICYCLE"]
        case .bikeRental:
            return ["mode": "BICYCLE", "qualifier": "RENT"]
        case .transitBikeRental:
            // Unreachable: `wireTransportModes` expands composites before this
            // mapping ever runs; the arm exists only for switch exhaustiveness.
            return ["mode": "TRANSIT"]
        case .transit, .walk, .car:
            return ["mode": mode.rawValue]
        }
    }

    /// Synthesizes the REST-style request parameters echoed back in `OTPResponse`.
    private static func requestParameters(for request: TripPlanRequest) -> RequestParameters {
        RequestParameters(
            fromPlace: request.origin.formattedForAPI,
            toPlace: request.destination.formattedForAPI,
            time: request.time.formattedTripTime,
            date: request.date.formattedTripDate,
            mode: request.transportModesString,
            arriveBy: request.arriveBy ? "true" : "false",
            maxWalkDistance: String(request.maxWalkDistance),
            wheelchair: request.wheelchairAccessible ? "true" : "false"
        )
    }

    /// Normalizes the base URL into the GTFS GraphQL endpoint by appending `gtfs/v1`.
    /// A REST-style trailing `routers/<id>` segment is stripped first so that either
    /// flavor of server URL works.
    /// - Parameter url: The base URL to normalize
    /// - Returns: The GraphQL endpoint URL
    private static func normalizeEndpointURL(_ url: URL) -> URL {
        var urlString = url.strippingOTPRouterPath().absoluteString

        while urlString.hasSuffix("/") {
            urlString.removeLast()
        }

        if !urlString.hasSuffix("/gtfs/v1") {
            urlString += "/gtfs/v1"
        }

        return URL(string: urlString)!
    }

    // MARK: - GraphQL Query

    /// The GTFS GraphQL API `plan` query. Requests only the fields OTPKit's models consume,
    /// mirroring what the OTP 1.x REST API returns.
    ///
    /// The `via` argument only exists in the query document when the request actually
    /// carries a via point: GraphQL validates documents statically, and `plan`'s `via`
    /// argument (with its `PlanViaLocationInput` type) only exists on OTP 2.7+ — a
    /// document that always declared it would break every plan request, transit
    /// included, against older 2.x servers.
    static func planQuery(includingVia: Bool) -> String { // swiftlint:disable:this function_body_length
        let viaDeclaration = includingVia ? "\n      $via: [PlanViaLocationInput!]" : ""
        let viaArgument = includingVia ? "\n        via: $via" : ""
        return """
    query TripPlan(
      $from: InputCoordinates!
      $to: InputCoordinates!
      $date: String!
      $time: String!
      $transportModes: [TransportMode!]
      $arriveBy: Boolean
      $wheelchair: Boolean
      $maxWalkDistance: Float\(viaDeclaration)
    ) {
      plan(
        from: $from
        to: $to
        date: $date
        time: $time
        transportModes: $transportModes
        arriveBy: $arriveBy
        wheelchair: $wheelchair
        maxWalkDistance: $maxWalkDistance\(viaArgument)
      ) {
        date
        from { name lon lat vertexType }
        to { name lon lat vertexType }
        routingErrors { code description }
        itineraries {
          duration
          startTime
          endTime
          walkTime
          waitingTime
          walkDistance
          elevationLost
          elevationGained
          numberOfTransfers
          legs {
            startTime
            endTime
            mode
            route {
              shortName
              type
              color
              textColor
              agency { name }
            }
            from {
              name lon lat vertexType stop { gtfsId code }
              vehicleRentalStation { stationId }
              rentalVehicle { vehicleId }
            }
            to {
              name lon lat vertexType stop { gtfsId code }
              vehicleRentalStation { stationId }
              rentalVehicle { vehicleId }
            }
            legGeometry { points length }
            distance
            transitLeg
            rentedBike
            duration
            realTime
            departureDelay
            arrivalDelay
            headsign
            intermediatePlaces { name lon lat vertexType stop { gtfsId code } }
            steps { distance streetName relativeDirection lon lat }
          }
        }
      }
    }
    """
    }

    /// The GTFS GraphQL API `vehicleRentalsByBbox` query. Returns the `RentalPlace`
    /// union; `__typename` discriminates stations from free-floating vehicles.
    static let rentalsQuery = """
    query VehicleRentalsByBbox(
      $minLat: CoordinateValue!
      $maxLat: CoordinateValue!
      $minLon: CoordinateValue!
      $maxLon: CoordinateValue!
    ) {
      vehicleRentalsByBbox(
        minimumLatitude: $minLat
        maximumLatitude: $maxLat
        minimumLongitude: $minLon
        maximumLongitude: $maxLon
      ) {
        __typename
        ... on VehicleRentalStation {
          stationId
          name
          lat
          lon
          vehiclesAvailable
          spacesAvailable
          allowPickupNow
          allowDropoffNow
          operative
          rentalNetwork { networkId url }
          rentalUris { ios android web }
          availableVehicles {
            total
            byType { count vehicleType { formFactor } }
          }
          availableSpaces { total }
        }
        ... on RentalVehicle {
          vehicleId
          name
          lat
          lon
          allowPickupNow
          operative
          rentalNetwork { networkId url }
          rentalUris { ios android web }
          vehicleType { formFactor propulsionType }
          fuel { percent range }
        }
      }
    }
    """
}
