//
//  DirectionLegWalkView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

struct DirectionLegWalkView: View {
    let leg: Leg
    @State private var showSteps = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 24))
                    .padding()
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Walk to \(leg.to.name)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        Formatters.formatDistance(Int(leg.distance)) +
                        ", about " +
                        Formatters.formatTimeDuration(leg.duration)
                    )
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Toggle Button
                if let steps = leg.steps, !steps.isEmpty {
                    Button(action: { showSteps.toggle() }) {
                        Image(systemName: showSteps ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            //MARK: Expandable Steps List View
            if showSteps, let steps = leg.steps {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(steps, id: \.self) { step in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)

                            Text(stepDescription(for: step))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, 40)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// Generates a user-friendly step description.
    private func stepDescription(for step: Step) -> String {
        if let direction = step.relativeDirection {
            return "\(direction.capitalized) onto \(step.streetName), walk \(Formatters.formatDistance(Int(step.distance)))."
        } else {
            return "Walk along \(step.streetName) for \(Formatters.formatDistance(Int(step.distance)))."
        }
    }
}

#Preview {
    DirectionLegWalkView(leg: PreviewHelpers.buildLeg())
}
