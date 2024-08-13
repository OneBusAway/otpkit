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

/**
 A simple way to construct a `debugDescription` property for an object.

 Here's how you might use it:

        public override var debugDescription: String {
            var descriptionBuilder = DebugDescriptionBuilder(baseDescription: super.debugDescription)
            descriptionBuilder.add(key: "id", value: id)
            return descriptionBuilder.description
        }
 */
public struct DebugDescriptionBuilder {
    let baseDescription: String
    var properties = [String: Any]()

    public init(baseDescription: String) {
        self.baseDescription = baseDescription
    }

    public mutating func add(key: String, value: Any?) {
        properties[key] = value ?? "(nil)"
    }

    public var description: String {
        "\(baseDescription) \(properties)"
    }
}
