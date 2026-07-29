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

import SwiftUI

extension Color {
    /// Rental purple (#7B4FD1). Every rental surface — browse-layer pins,
    /// trip-planner pickup/dropoff markers, and rail rows — shares this color
    /// so rentals read as one system.
    static let otpRentalPurple = Color(red: 0x7B / 255.0, green: 0x4F / 255.0, blue: 0xD1 / 255.0)
}
