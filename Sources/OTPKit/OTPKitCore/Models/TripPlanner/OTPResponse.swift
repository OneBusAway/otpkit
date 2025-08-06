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

/// Represents the response from the OpenTripPlanner (OTP) API.
public struct OTPResponse: Codable, Hashable {
    /// Parameters used in the request that generated this response.
    public let requestParameters: RequestParameters

    /// Optional `Plan` object containing detailed itinerary plans if the request was successful.
    public let plan: Plan?

    /// Optional `ErrorResponse` object containing error details if the request failed.
    public let error: ErrorResponse?
}
