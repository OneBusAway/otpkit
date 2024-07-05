//
//  OriginDestinationView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import SwiftUI

/// OriginDestinationView is the main view for setting up Origin/Destination in OTPKit.
/// It consists a list of Origin and Destination along with the `MapKit`
public struct OriginDestinationView: View {
    @StateObject private var originDestinationEnvironment = OriginDestinationSheetEnvironment()

    @State private var isSheetOpened = false

    static let mockCoordinate = CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275)

    static let mockSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

    @State private var region = MKCoordinateRegion(center: mockCoordinate, span: mockSpan)

    public var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(.follow))
                .edgesIgnoringSafeArea(.all)
                .sheet(isPresented: $isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(originDestinationEnvironment)
                }

            VStack {
                List {
                    Button(action: {
                        isSheetOpened.toggle()
                        originDestinationEnvironment.sheetState = .origin
                    }, label: {
                        HStack(spacing: 16) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 30, height: 30)
                                )
                            Text("Origin UI")
                        }
                    })

                    Button(action: {
                        isSheetOpened.toggle()
                        originDestinationEnvironment.sheetState = .destination
                    }, label: {
                        HStack(spacing: 16) {
                            Image(systemName: "mappin")
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 30, height: 30)
                                )
                            Text("Destination UI")
                        }
                    })
                }
                .frame(height: 135)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)

                Spacer()
            }
        }
    }
}

#Preview {
    OriginDestinationView()
}
