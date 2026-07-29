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

// Wire-level plumbing shared by the REST and GraphQL API services.

extension OTPKitError {
    /// The generic "the server response can't be parsed" API error.
    static func invalidResponse(statusCode: Int? = nil) -> OTPKitError {
        .apiError(
            OTPLoc("error.invalid_response", comment: "Shown when the server response can't be parsed"),
            statusCode: statusCode
        )
    }
}

extension URLDataLoader {
    /// Performs the request and returns the response body, throwing
    /// `OTPKitError.invalidResponse` unless the server returned HTTP 200.
    func validatedData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await data(for: request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw OTPKitError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode)
        }

        return data
    }
}

extension JSONDecoder {
    /// A decoder configured for OTP wire responses, whose dates are epoch milliseconds.
    static func otpDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }
}

extension URL {
    /// True if the URL path ends with an OTP REST router segment (`routers/<id>`).
    var hasOTPRouterPath: Bool {
        path().contains(#/routers/[^/]+/?$/#)
    }

    /// Returns a URL with any trailing `routers/<id>` segment removed.
    func strippingOTPRouterPath() -> URL {
        guard hasOTPRouterPath else { return self }

        var urlString = absoluteString
        if let routersRange = urlString.range(of: "routers/[^/]+/?$", options: .regularExpression) {
            urlString.removeSubrange(routersRange)
        }

        return URL(string: urlString) ?? self
    }
}
