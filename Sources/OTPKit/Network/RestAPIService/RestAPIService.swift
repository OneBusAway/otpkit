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
import os.log

// swiftlint:disable function_parameter_count

/// Actor-based REST API client for OTP trip planning
public actor RestAPIService: APIService {
    public let baseURL: URL
    public nonisolated let dataLoader: URLDataLoader
    public nonisolated let logger = os.Logger(subsystem: "otpkit", category: "RestAPIService")

    /// Creates a REST API client
    /// - Parameters:
    ///   - baseURL: Base URL of the API
    ///   - dataLoader: Network loader (defaults to `URLSession.shared`)
    public init(
        baseURL: URL,
        dataLoader: URLDataLoader = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.dataLoader = dataLoader
    }

    /// Fetches a trip plan using a `TripPlanRequest`
    public func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
        try await fetchPlan(
            fromPlace: request.origin.formattedForAPI,
            toPlace: request.destination.formattedForAPI,
            time: request.time.formattedTripTime,
            date: request.date.formattedTripDate,
            mode: request.transportModesString,
            arriveBy: request.arriveBy,
            maxWalkDistance: request.maxWalkDistance,
            wheelchair: request.wheelchairAccessible
        )
    }

    /// Fetches a trip plan from the API
    public func fetchPlan(
        fromPlace: String,
        toPlace: String,
        time: String,
        date: String,
        mode: String,
        arriveBy: Bool,
        maxWalkDistance: Int,
        wheelchair: Bool
    ) async throws -> OTPResponse {
        var components = URLComponents(
            url: buildURL(endpoint: "plan"),
            resolvingAgainstBaseURL: false
        )!

        components.queryItems = [
            .init(name: "fromPlace", value: fromPlace),
            .init(name: "toPlace", value: toPlace),
            .init(name: "time", value: time),
            .init(name: "date", value: date),
            .init(name: "mode", value: mode),
            .init(name: "arriveBy", value: arriveBy ? "true" : "false"),
            .init(name: "maxWalkDistance", value: String(maxWalkDistance)),
            .init(name: "wheelchair", value: wheelchair ? "true" : "false")
        ]

        let request = URLRequest(url: components.url!)
        logger.info("Fetching trip plan: \(components.url!.absoluteString)")

        do {
            let (data, response) = try await dataLoader.data(for: request)

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                logger.error("API error - Status: \(statusCode), URL: \(components.url!.absoluteString)")
                throw OTPKitError.apiError("Server returned invalid response", statusCode: statusCode)
            }

            logger.info("Received response: \(httpResponse.statusCode) - \(data.count) bytes")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            return try decoder.decode(OTPResponse.self, from: data)
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Builds a URL for the given endpoint
    private func buildURL(endpoint: String) -> URL {
        baseURL.appending(path: endpoint)
    }
}

// swiftlint:enable function_parameter_count
