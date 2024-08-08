//
//  DireactionLegOriginDestinationView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DireactionLegOriginDestinationView: View {
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 24) {
            Group {
                Image(systemName: "mappin")
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
            }.frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                Text(description)
            }
        }
    }
}

#Preview {
    DireactionLegOriginDestinationView(title: "Origin", description: "Unknown Location")
}
