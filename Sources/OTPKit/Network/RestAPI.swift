/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

// swiftlint:disable function_parameter_count

/// An actor representing a REST API client for making network requests
public actor RestAPI {
    
    /// Initializes a new instance of RestAPI
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for the API
    ///   - dataLoader: The data loader to use for network requests (defaults to URLSession.shared)
    public init(
        baseURL: URL,
        dataLoader: URLDataLoader = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.dataLoader = dataLoader
    }

    /// The base URL for the API
    public let baseURL: URL
    
    /// The data loader used for network requests
    public nonisolated let dataLoader: URLDataLoader

    /// Fetches a trip plan from the API
    ///
    /// - Parameters:
    ///   - fromPlace: The starting location of the trip
    ///   - toPlace: The destination of the trip
    ///   - time: The time of the trip
    ///   - date: The date of the trip
    ///   - mode: The transportation mode(s) for the trip
    ///   - arriveBy: Whether the trip should arrive by the specified time
    ///   - maxWalkDistance: The maximum walking distance in meters
    ///   - wheelchair: Whether the trip should be wheelchair accessible
    ///
    /// - Returns: An OTPResponse object containing the trip plan
    /// - Throws: An error if the network request fails or the response is invalid
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
        var components = URLComponents(url: buildURL(endpoint: "plan"), resolvingAgainstBaseURL: false)!

        components.queryItems = [
            URLQueryItem(name: "fromPlace", value: fromPlace),
            URLQueryItem(name: "toPlace", value: toPlace),
            URLQueryItem(name: "time", value: time),
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "arriveBy", value: arriveBy ? "true" : "false"),
            URLQueryItem(name: "maxWalkDistance", value: String(maxWalkDistance)),
            URLQueryItem(name: "wheelchair", value: wheelchair ? "true" : "false")
        ]

        let request = URLRequest(url: components.url!)
        let (data, response) = try await dataLoader.data(for: request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        // Decode the JSON data to the OTPResponse struct
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decodedResponse = try decoder.decode(OTPResponse.self, from: data)

        return decodedResponse
    }

    /// Builds a URL for the given endpoint
    ///
    /// - Parameter endpoint: The API endpoint
    /// - Returns: A URL combining the base URL and the endpoint
    private func buildURL(endpoint: String) -> URL {
        baseURL.appending(path: endpoint)
    }
}

// swiftlint:enable function_parameter_count
