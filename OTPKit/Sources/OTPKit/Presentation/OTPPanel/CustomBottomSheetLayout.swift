//
//  CustomBottomSheetLayout.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import Foundation
import FloatingPanel

/// Custom layout for bottom sheet that respects BottomSheetConfiguration
internal class CustomBottomSheetLayout: FloatingPanelLayout {
    private let configuration: BottomSheetConfiguration

    init(configuration: BottomSheetConfiguration) {
        self.configuration = configuration
    }

    var position: FloatingPanelPosition { .bottom }

    var initialState: FloatingPanelState {
        configuration.initialPosition.floatingPanelState
    }

    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [:]

        for position in configuration.supportedPositions {
            switch position {
            case .tip:
                anchors[.tip] = FloatingPanelLayoutAnchor(absoluteInset: 140.0, edge: .bottom, referenceGuide: .safeArea)
            case .half:
                anchors[.half] = FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea)
            case .full:
                anchors[.full] = FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea)
            }
        }

        return anchors
    }
}