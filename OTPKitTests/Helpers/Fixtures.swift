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
@testable import OTPKit

class Fixtures {
    private class var testBundle: Bundle {
        Bundle(for: self)
    }

    /// Converts the specified dictionary to a model object of type `T`.
    /// - Parameters:
    ///   - type: The model type to which the dictionary will be converted.
    ///   - dictionary: The data
    /// - Returns: A model object
    class func dictionaryToModel<T>(type: T.Type, dictionary: [String: Any]) throws -> T where T: Decodable {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        return try JSONDecoder().decode(type, from: jsonData)
    }

    /// Returns the path to the specified file in the test bundle.
    /// - Parameter fileName: The file name, e.g. "regions.json"
    class func path(to fileName: String) -> String {
        testBundle.path(forResource: fileName, ofType: nil)!
    }

    /// Encodes and decodes the provided `Codable` object. Useful for testing roundtripping.
    /// - Parameter type: The object type.
    /// - Parameter model: The object or objects.
    class func roundtripCodable<T>(type: T.Type, model: T) throws -> T where T: Codable {
        let encoded = try PropertyListEncoder().encode(model)
        let decoded = try PropertyListDecoder().decode(type, from: encoded)
        return decoded
    }

    /// Loads data from the specified file name, searching within the test bundle.
    /// - Parameter file: The file name to load data from. Example: `stop_data.pb`.
    class func loadData(file: String) -> Data {
        NSData(contentsOfFile: path(to: file))! as Data
    }
}
