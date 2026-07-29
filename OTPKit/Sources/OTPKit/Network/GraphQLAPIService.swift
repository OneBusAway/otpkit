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

/// Actor-based GraphQL API client for OTP 2.x trip planning via the GTFS GraphQL API.
public actor GraphQLAPIService: APIService {
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
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": Self.planQuery,
            "variables": Self.planVariables(for: request)
        ])

        Logger.main.info("Fetching trip plan via GraphQL: \(self.endpointURL.absoluteString)")

        let data = try await dataLoader.validatedData(for: urlRequest)
        let envelope = try JSONDecoder.otpDecoder().decode(GraphQLResponseEnvelope.self, from: data)

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

    // MARK: - Request Building

    /// Builds the GraphQL `variables` payload for a trip plan request.
    private static func planVariables(for request: TripPlanRequest) -> [String: Any] {
        [
            "from": ["lat": request.origin.latitude, "lon": request.origin.longitude],
            "to": ["lat": request.destination.latitude, "lon": request.destination.longitude],
            "date": request.date.formattedTripDate,
            "time": request.time.formattedTripTime,
            "transportModes": request.transportModes.map { ["mode": graphQLModeName(for: $0)] },
            "arriveBy": request.arriveBy,
            "wheelchair": request.wheelchairAccessible,
            "maxWalkDistance": Double(request.maxWalkDistance)
        ]
    }

    /// The GraphQL `Mode` enum value for a transport mode. `TransportMode.rawValue` is the
    /// OTP 1.x REST token, which mostly — but not always — matches the GraphQL vocabulary.
    private static func graphQLModeName(for mode: TransportMode) -> String {
        switch mode {
        case .bike:
            return "BICYCLE"
        case .transit, .walk, .car:
            return mode.rawValue
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
    static let planQuery = """
    query TripPlan(
      $from: InputCoordinates!
      $to: InputCoordinates!
      $date: String!
      $time: String!
      $transportModes: [TransportMode!]
      $arriveBy: Boolean
      $wheelchair: Boolean
      $maxWalkDistance: Float
    ) {
      plan(
        from: $from
        to: $to
        date: $date
        time: $time
        transportModes: $transportModes
        arriveBy: $arriveBy
        wheelchair: $wheelchair
        maxWalkDistance: $maxWalkDistance
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
            from { name lon lat vertexType stop { gtfsId code } }
            to { name lon lat vertexType stop { gtfsId code } }
            legGeometry { points length }
            distance
            transitLeg
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
