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
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner
    @State private var isSheetOpened = false

    // Public Initializer
    public init() {}

    private func originDestinationField(icon: String, text: String, action: @escaping () -> Void) -> some View {
        
        Button(action: action, label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .background(
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                    )
                
                Text(text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }
            .frame(minHeight: 35, maxHeight: 40)
        })
        .foregroundStyle(.foreground)

    }
    
    public var body: some View {
        VStack {
            List {
                
                originDestinationField(icon: "paperplane.fill", text: tripPlanner.originName) {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .origin
                }
                
                originDestinationField(icon: "mappin", text: tripPlanner.destinationName) {
                    sheetEnvironment.isSheetOpened.toggle()
                    tripPlanner.originDestinationState = .destination
                }
            }
            .frame(minHeight: 135, maxHeight: 170)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    OriginDestinationView()
}
