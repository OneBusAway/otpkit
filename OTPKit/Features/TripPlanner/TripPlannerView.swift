//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 30/07/24.
//

import SwiftUI

public struct TripPlannerView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared

    public init() {}

    public var body: some View {
        VStack {
            Button(action: {
                locationManagerService.resetTripPlanner()
            }, label: {
                Text("Start")
            })
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)

            Button(action: {
                locationManagerService.resetTripPlanner()
            }, label: {
                Text("Cancel")
            })
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    TripPlannerView()
}
