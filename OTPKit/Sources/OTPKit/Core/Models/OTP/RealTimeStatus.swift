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

import SwiftUI

/// The real-time schedule status of a leg's departure or arrival.
///
/// The four cases render with fixed colors that mean the same thing at every
/// agency: green (on time), violet (late), red (early), blue (scheduled).
public enum RealTimeStatus: Hashable {
    /// Real-time data says the vehicle is running on schedule.
    case onTime

    /// Real-time data says the vehicle is running behind schedule.
    case late(minutes: Int)

    /// Real-time data says the vehicle is running ahead of schedule.
    case early(minutes: Int)

    /// No real-time data; times come from the static schedule.
    case scheduled

    /// Builds a status from a leg's `realTime` flag and a delay in seconds
    /// (positive = late).
    public init(realTime: Bool?, delaySeconds: Int?) {
        guard realTime == true, let delaySeconds else {
            self = .scheduled
            return
        }

        let minutes = Int((Double(delaySeconds) / 60.0).rounded())
        if minutes > 0 {
            self = .late(minutes: minutes)
        } else if minutes < 0 {
            self = .early(minutes: -minutes)
        } else {
            self = .onTime
        }
    }

    /// The rider-facing status string, e.g. "On time" or "7 min late".
    public var localizedDescription: String {
        switch self {
        case .onTime:
            return OTPLoc("status.on_time", comment: "Vehicle is running on schedule")
        case .late(let minutes):
            return OTPLoc("status.late_fmt", comment: "Vehicle is running n minutes behind schedule", minutes)
        case .early(let minutes):
            return OTPLoc("status.early_fmt", comment: "Vehicle is running n minutes ahead of schedule", minutes)
        case .scheduled:
            return OTPLoc("status.scheduled", comment: "No real-time data; schedule time shown")
        }
    }

    /// The fixed status color. These are intentionally not themeable — they
    /// carry the same meaning at every agency.
    public var color: Color {
        switch self {
        case .onTime:
            return Color(red: 0.133, green: 0.773, blue: 0.369) // #22c55e
        case .late:
            return Color(red: 0.486, green: 0.227, blue: 0.929) // #7c3aed
        case .early:
            return Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444
        case .scheduled:
            return Color(red: 0.231, green: 0.510, blue: 0.965) // #3b82f6
        }
    }
}
