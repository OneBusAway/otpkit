//
//  OriginDestinationView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import SwiftUI
import MapKit

struct OriginDestinationView: View {
    @StateObject private var viewModel = OriginDestinationViewModel()
    
    @StateObject private var originDestinationEnvironment = OriginDestinationSheetEnvironment()
    
    @State private var isSheetOpened = false
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    var body: some View {
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

            
            
            Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(.follow))
                .frame(width: 400, height: 300)
            
                .sheet(isPresented: $isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(originDestinationEnvironment)
                }
        }

        


    }
}

#Preview {
    OriginDestinationView()
}
