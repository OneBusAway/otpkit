//
//  DirectionLegUnknownView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegUnknownView: View {
    let leg: Leg

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Unknown Transit Mode")
                    .font(.headline)
                Text(leg.mode)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    DirectionLegUnknownView(leg: PreviewHelpers.buildLeg())
}
