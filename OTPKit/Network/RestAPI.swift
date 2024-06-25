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

public actor RestAPI {
    public init(
        baseURL: URL,
        dataLoader: URLDataLoader = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.dataLoader = dataLoader
    }

    public let baseURL: URL
    public nonisolated let dataLoader: URLDataLoader

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

    private func buildURL(endpoint: String) -> URL {
        baseURL.appending(path: endpoint)
    }
}

// swiftlint:enable function_parameter_count
