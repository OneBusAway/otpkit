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

/// `ErrorResponse` represents an error structure used across the application to handle and represent
/// OTP errors uniformly.
public struct ErrorResponse: Codable, Hashable {
    /// A unique identifier for the error.
    public let id: Int

    /// A descriptive message associated with the error, providing more detailed information about what went wrong.
    /// This message can be presented to the user or used in debugging to provide context about the error.
    public let message: String
}
