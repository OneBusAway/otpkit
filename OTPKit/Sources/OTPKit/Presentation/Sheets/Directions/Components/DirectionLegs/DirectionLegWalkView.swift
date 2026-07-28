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
            DirectionLegContainerView {
                Image(systemName: "figure.walk")
                    .font(.system(size: 24))
            } rightContent: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(OTPLoc("leg.walk_to", comment: "Instruction to walk to a place", leg.to.name))
                            .font(.title3)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(OTPLoc(
                            "leg.walk_distance_duration",
                            comment: "Walking distance followed by approximate duration",
                            Formatters.formatDistance(Int(leg.distance)),
                            Formatters.formatTimeDuration(leg.duration)
                        ))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    // Toggle Button
                    if let steps = leg.steps, !steps.isEmpty {
                        Button(action: { showSteps.toggle() }, label: {
                            Image(systemName: showSteps ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // MARK: Expandable Steps List View
            if showSteps, let steps = leg.steps {
                HStack(alignment: .top, spacing: 12) {
                    // Step descriptions
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(steps, id: \.self) { step in
                            Text(stepDescription(for: step))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
    }

    /// Generates a user-friendly step description.
    private func stepDescription(for step: Step) -> String {
        if let direction = step.directionDisplayName {
            return OTPLoc(
                "leg.step_turn",
                comment: "A walking step: turn direction, street name, distance",
                direction,
                step.streetName,
                Formatters.formatDistance(Int(step.distance))
            )
        } else {
            return OTPLoc(
                "leg.step_continue",
                comment: "A walking step with no turn: street name, distance",
                step.streetName,
                Formatters.formatDistance(Int(step.distance))
            )
        }
    }
}

#Preview {
    DirectionLegWalkView(leg: PreviewHelpers.buildLeg())
}
