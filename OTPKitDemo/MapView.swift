//
//  MapView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import OTPKit
import SwiftUI

struct MarkerItem: Identifiable {
    var id: UUID = .init()
    var title: String
    var coordinate: CLLocationCoordinate2D
}

public struct MapView: View {
    @StateObject private var sheetEnvironment = OriginDestinationSheetEnvironment()

    @StateObject private var locationServices = UserLocationServices.shared

//    static let mockCoordinate = CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275)
//    static let mockSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

//    @State private var region = MKCoordinateRegion(center: mockCoordinate, span: mockSpan)

    @State private var selectedMapPoint: [MarkerItem] = []

    public var body: some View {
        ZStack {
            MapReader { proxy in
                Map(initialPosition: .automatic, interactionModes: .all) {
                    ForEach(selectedMapPoint) { point in
                        Marker(point.title, coordinate: point.coordinate)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .sheet(isPresented: $sheetEnvironment.isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(sheetEnvironment)
                }
                .onTapGesture { tappedLocation in
                    guard let coordinate = proxy.convert(tappedLocation, from: .local) else { return }
                    let foobarItem = MarkerItem(title: "Foobar", coordinate: coordinate)
                    selectedMapPoint.append(foobarItem)
                }
            }
            OriginDestinationView()
                .environmentObject(sheetEnvironment)
        }
        .onAppear {
            locationServices.checkIfLocationServicesIsEnabled()
        }
    }
}

#Preview {
    MapView()
}
