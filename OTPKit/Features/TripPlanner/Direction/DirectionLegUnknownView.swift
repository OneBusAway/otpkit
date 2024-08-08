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
        HStack(spacing: 24) {
            Text("\(leg.mode): \(Formatters.formatTimeDuration(leg.duration))")
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .foregroundStyle(.gray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(height: 40)
    }
}

#Preview {
    DirectionLegUnknownView(leg: PreviewHelpers.buildLeg())
}
