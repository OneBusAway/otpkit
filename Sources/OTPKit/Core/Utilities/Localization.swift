//
//  OTPLocalization.swift
//  OTPKit
//
//  Created by Manu on 2025-07-08.
//

import Foundation
import SwiftUI

/// Handles loading localized strings from the package's resource bundle.
public struct Localization {
    /// The bundle where localized resources are stored (SPM `.module`).
    public static var bundle: Bundle { .module }

    /// Returns a localized string for the given key.
    public static func string(_ key: String,
                              in bundle: Bundle? = nil,
                              tableName: String? = nil,
                              comment: String = "") -> String {
        NSLocalizedString(key,
                          tableName: tableName,
                          bundle: bundle ?? self.bundle,
                          comment: comment)
    }

    /// Returns a localized and formatted string for the given key.
    public static func string(_ key: String,
                              in bundle: Bundle? = nil,
                              tableName: String? = nil,
                              comment: String = "",
                              args: CVarArg...) -> String {
        let format = string(key, in: bundle, tableName: tableName, comment: comment)
        return String(format: format, arguments: args)
    }
}

/// Quick helper for non-SwiftUI contexts (e.g. logging, UIKit).
public func OTPLoc(_ key: String,
                   table: String = "Localizable",
                   comment: String = "",
                   _ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key,
                                   tableName: table,
                                   bundle: .module,
                                   value: "",
                                   comment: comment)
    guard arguments.isEmpty == false else { return format }
    return String(format: format, arguments: arguments)
}
