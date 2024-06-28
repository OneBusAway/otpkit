//
//  OriginDestinationSheetEnvironment.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation

/// OriginDestinationSheetState responsible for managing states of the shown `OriginDestinationSheetView`
/// - Enums:
///     - origin: This manage origin state of the trip planner
///     - destination: This manage destination state of the trip planner
enum OriginDestinationSheetState {
    case origin
    case destination
}

/// OriginDestinationSheetEnvironment responsible for manage the environment of `OriginDestination` features
/// - sheetState: responsible for managing shown sheet in `OriginDestinationView`
/// - selectedValue: responsible for managing selected value when user taped the list in `OriginDestinationSheetView`
final class OriginDestinationSheetEnvironment: ObservableObject {
    @Published var sheetState: OriginDestinationSheetState = .origin
    @Published var selectedValue: String = ""
}
