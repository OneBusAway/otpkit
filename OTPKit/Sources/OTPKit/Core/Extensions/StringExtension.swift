//
//  StringExtension.swift
//  OTPKit
//

import Foundation

extension String {
    /// Canonicalizes an OTP wire token for enum lookup: trims, uppercases, and treats
    /// spaces as underscores so `"Cable Car"` and `"cable_car"` both match `CABLE_CAR`.
    var normalizedOTPToken: String {
        trimmingCharacters(in: .whitespaces)
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")
    }

    /// Uppercases only the first character, leaving the rest untouched: `e-bike` becomes
    /// `E-bike`. Unlike `capitalized`, this never lowercases the remainder.
    var capitalizedFirst: String {
        isEmpty ? self : prefix(1).uppercased() + dropFirst()
    }

    /// True when this is a known rental-feed placeholder name ("Default vehicle type")
    /// that must never reach the UI. The single source of truth for the check —
    /// `VehicleRental.displayLabel`, `Leg.riderFacingName(of:)`, and the rail views
    /// all decide their own substitution policy on top of this one predicate.
    var isRentalPlaceholderName: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "default vehicle type"
    }

    /// Renders an unrecognized OTP token as readable text: `SPIN_AROUND` becomes `Spin Around`.
    ///
    /// Last-resort display fallback for a mode or direction this client doesn't know about.
    /// The result is untranslated English by construction — it exists so a new server-side
    /// token degrades to something readable rather than shouting a raw wire token.
    var humanizedOTPToken: String {
        replacingOccurrences(of: "_", with: " ").capitalized
    }
}
