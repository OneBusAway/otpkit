//
//  GetDirectionsButton.swift
//  OTPKit
//
//  Created by Manu on 2025-03-30.
//

import SwiftUI

struct GetDirectionsButton: View {
    @Environment(TripPlannerService.self) private var tripPlanner
    let originName: String
    let destinationName: String

    let action: VoidBlock

    var body: some View {
        VStack {
            Button(action: {
                action()
            }) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.title3)
                    Text("Get Directions")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(originName.isEmpty || destinationName.isEmpty ? Color.gray : Color.green)
                .cornerRadius(12)
                .opacity(originName.isEmpty || destinationName.isEmpty ? 0.6 : 1.0)
            }
            .disabled(originName.isEmpty || destinationName.isEmpty)
        }
        .padding(.horizontal, 12)
    }
}
