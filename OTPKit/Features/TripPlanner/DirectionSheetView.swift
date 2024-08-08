//
//  DirectionSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI

public struct StepsSheetView: View {
    @ObservedObject private var locationManagerService = LocationManagerService.shared

    public init() {}
    private func generateStepView(step: Step) -> some View {
        Group {
            switch step.relativeDirection {
            case "DEPART", "CONTINUE":
                Image(systemName: "arrow.up")
            case "LEFT", "HARD_LEFT":
                Image(systemName: "arrow.turn.up.left")
            case "SLIGHTLY_LEFT":
                Image(systemName: "arrow.up.left")
            case "SLIGHTLY_RIGHT":
                Image(systemName: "arrow.up.right")
            case "HARD_RIGHT", "RIGHT":
                Image(systemName: "arrow.turn.up.right")
            case "CIRCLE_CLOCKWISE":
                Image(systemName: "arrow.clockwise.circle")
            case "CIRCLE_COUNTERCLOCKWISE":
                Image(systemName: "arrow.counterclockwise.circle")
            case "ELEVATOR":
                Image(systemName: "arrow.up.and.down")
            case "UTURN_LEFT":
                Image(systemName: "arrow.uturn.left")
            case "UTURN_RIGHT":
                Image(systemName: "arrow.uturn.right")
            default:
                Image(systemName: "arrow.up")
            }
        }
    }

    public var body: some View {
        List {
            if let itinerary = locationManagerService.selectedItinerary {
                ForEach(itinerary.legs, id: \.self) { leg in
                    if let steps = leg.steps {
                        ForEach(steps, id: \.self) { step in
                            generateStepView(step: step)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    StepsSheetView()
}
