//
//  PanelHostingController.swift
//
//
//  Created by Aaron Brethorst on 10/26/25.
//

import SwiftUI
import UIKit

public extension UIViewController {

    /// Sets the receiver's adaptive sheet presentation controller's `selectedDetentIdentifier` to `identifier`. tl;dr: make the sheet change size.
    /// - Parameter identifier: The detent identifier, e.g. `.large`, `.medium`, `.tip`.
    ///
    /// This method is only meant to be called on instances of `PanelHostingController`.
    public func animateToDetentIdentifier(_ identifier: UISheetPresentationController.Detent.Identifier) {
        guard let popover = popoverPresentationController else {
            return
        }
        let sheet = popover.adaptiveSheetPresentationController

        sheet.animateChanges {
            sheet.selectedDetentIdentifier = identifier
        }
    }
}

public extension UISheetPresentationController.Detent.Identifier {

    /// A tiny detent for sheets. Only defined on `PanelHostingController`
    static let tip = UISheetPresentationController.Detent.Identifier("tip")
}

/// A `UIHostingController` subclass that is meant to host `TripPlannerView` and offers SwiftUI-style sheet
/// support, complete with a semi-modal experience and a `.tip`-sized detent.
public final class PanelHostingController<Content: View>: UIHostingController<Content> {
    public override init(rootView: Content) {
        super.init(rootView: rootView)

        modalPresentationStyle = .popover
        if let popover = popoverPresentationController {
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [
                UISheetPresentationController.Detent.custom(identifier: .tip) { _ in 250 },
                .medium(),
                .large()
            ]
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
