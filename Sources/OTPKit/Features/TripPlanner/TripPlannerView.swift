//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 30/07/24.
//

import SwiftUI

public struct TripPlannerView: View {
    @EnvironmentObject private var tripPlanner: TripPlannerService

    public init(text: String) {
        self.text = text
    }

    private let text: String

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .fontWeight(.semibold)
                .padding(16)
            HStack {
                Button(action: {
                    tripPlanner.resetTripPlanner()
                }, label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(BorderedButtonStyle())

                Button(action: {
                    tripPlanner.isStepsViewPresented = true
                }, label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
        }
        .background(.thickMaterial)
    }
}

#Preview {
    TripPlannerView(text: "43 minutes, departs at 4:15 PM")
        .environmentObject(PreviewHelpers.buildTripPlannerService())
}
