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
        DirectionLegContainerView {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.gray)
        } rightContent: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(OTPLoc("leg.unknown_mode", comment: "Shown when a trip leg uses an unrecognized transit mode"))
                        .font(.headline)
                    Text(leg.modeDisplayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    DirectionLegUnknownView(leg: PreviewHelpers.buildLeg())
}
