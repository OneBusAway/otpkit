//
//  Sheet.swift
//  OTPKit
//
//  Created by Manu on 2025-07-11.
//

enum Sheet: String, CaseIterable, Identifiable {
    case tripResults
    case locationOptions
    case routeDetails
    case settings
    case search
    case dateTime

    var id: String { rawValue }
}
