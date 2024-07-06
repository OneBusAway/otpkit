//
//  MapView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import OTPKit
import SwiftUI

public struct MapView: View {
    @StateObject private var sheetEnvironment = OriginDestinationSheetEnvironment()

    static let mockCoordinate = CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275)
    static let mockSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

    @State private var region = MKCoordinateRegion(center: mockCoordinate, span: mockSpan)

    public var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(.follow))
                .edgesIgnoringSafeArea(.all)
                .sheet(isPresented: $sheetEnvironment.isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(sheetEnvironment)
                }

            OriginDestinationView()
                .environmentObject(sheetEnvironment)
        }
    }
}

#Preview {
    MapView()
}
