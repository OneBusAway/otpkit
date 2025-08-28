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

    @Environment(\.otpTheme) private var theme

    init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "mappin")
                .font(.system(size: 24))
                .padding(8)
                .background(theme.primaryColor)
                .foregroundStyle(.white)
                .clipShape(Circle())
                .frame(width: 40, height: 40)
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
