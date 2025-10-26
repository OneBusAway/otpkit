//
//  Enums.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/31/25.
//

public enum LocationMode {
    case origin
    case destination
}

enum Sheet: Identifiable, Hashable {
    case locationOptions(LocationMode)
    case directions
    case search(LocationMode)
    case advancedOptions

    var id: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }
}
