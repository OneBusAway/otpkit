//
//  UserDataServices.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import Foundation

final actor UserDefaultsServices {
    static let shared = UserDefaultsServices()
    private let userDefaults = UserDefaults.standard

    // MARK: - Saved Location Data

    func saveLocationData() {
//        userDefaults.set(<#T##value: Any?##Any?#>, forKey: <#T##String#>)
    }

    func deleteLocationData() {}
}
