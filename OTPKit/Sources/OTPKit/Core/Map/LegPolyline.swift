//
//  LegPolyline.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/28/25.
//

import MapKit
import UIKit

/// Custom MKPolyline subclass that stores color and identifier information
class LegPolyline: MKPolyline {
    var color: UIColor = .blue
    var lineWidth: CGFloat = 3.0
    var identifier: String = ""
    var lineDashPattern: [NSNumber]?
}
