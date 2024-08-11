//
//  DirectionLegOriginDestinationView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegOriginDestinationView: View {
    private let title: String
    private let description: String

    init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: "mappin")
                .font(.system(size: 24))
                .padding(8)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
                .frame(width: 40)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(description)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    DirectionLegOriginDestinationView(title: "Origin", description: "Unknown Location")
}
