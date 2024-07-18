//
//  MarkerItem.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 16/07/24.
//

import Foundation
import MapKit

public struct MarkerItem: Identifiable, Hashable {
    public let id: UUID = .init()
    public let item: MKMapItem
}
