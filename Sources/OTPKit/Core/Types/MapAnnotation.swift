//
//  MapAnnotation.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//
import SwiftUI
import MapKit

struct MapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let color: Color
}
