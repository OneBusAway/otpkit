//
//  OTPPointAnnotation.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/28/25.
//

import MapKit

/// Custom MKPointAnnotation subclass that stores type and identifier information
class OTPPointAnnotation: MKPointAnnotation {
    var identifier: String = ""
    var annotationType: OTPAnnotationType = .searchResult

    // Properties for route legend annotations
    var routeName: String?
    var routeBackgroundColor: UIColor?
    var routeTextColor: UIColor?
}
