//
//  SavedLocation.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation

struct SavedLocation: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    let latitude: Double
    let longitude: Double
}
