//
//  OriginDestinationSheetEnvironment.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation

enum OriginDestinationSheetState {
    case origin
    case destination
}

final class OriginDestinationSheetEnvironment: ObservableObject {
    @Published var sheetState: OriginDestinationSheetState = .origin
}
