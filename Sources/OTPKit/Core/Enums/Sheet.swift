//
//  Sheet.swift
//  OTPKit
//
//  Created by Manu on 2025-07-11.
//

enum Sheet: String, CaseIterable, Identifiable {
    case tripResults
    case locationOptions
    case directions
    case search
    case advancedOptions

    var id: String { rawValue }
}
 
