//
//  PresentationManager.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/11/24.
//

import SwiftUI

/// Manages the presentation state of dependent modal sheets.
///
/// In other words, instead of having to maintain several independent boolean values for determining which
/// sheet is currently visible, you can use `PresentationManager` to DRY up and orchestrate your
/// modal sheet state.
class PresentationManager<PresentationType: Identifiable>: ObservableObject {
    @Published var activePresentation: PresentationType?

    func present(_ presentationType: PresentationType) {
        activePresentation = presentationType
    }

    func dismiss() {
        activePresentation = nil
    }
}
