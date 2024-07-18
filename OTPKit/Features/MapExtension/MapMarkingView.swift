//
//  MapMarkingView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 18/07/24.
//

import SwiftUI

public struct MapMarkingView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared

    public init() {}
    public var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    locationManagerService.toggleMapMarkingMode(false)
                    locationManagerService.selectCoordinate()
                }, label: {
                    Text("Add Map Location")
                })
                .padding(.all)
                .background(Color.gray)
                .clipShape(.rect(cornerRadius: 12))

                Button(action: {
                    locationManagerService.toggleMapMarkingMode(false)
                    locationManagerService.selectCoordinate()
                }, label: {
                    Text("Cancel Map Location")
                })

                .padding(.all)
                .background(Color.gray)
                .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    MapMarkingView()
}
