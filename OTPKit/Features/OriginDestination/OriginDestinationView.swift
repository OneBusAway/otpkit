//
//  OriginDestinationView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 05/07/24.
//

import MapKit
import SwiftUI

/// OriginDestinationView is the main view for setting up Origin/Destination in OTPKit.
/// It consists a list of Origin and Destination along with the `MapKit`
public struct OriginDestinationView: View {
    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment
    @State private var isSheetOpened = false

    // Public Initializer
    public init() {}

    public var body: some View {
        VStack {
            List {
                Button(action: {
                    sheetEnvironment.isSheetOpened.toggle()
                    sheetEnvironment.sheetState = .origin
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
                    sheetEnvironment.isSheetOpened.toggle()
                    sheetEnvironment.sheetState = .destination
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
        }
    }
}

#Preview {
    OriginDestinationView()
}
