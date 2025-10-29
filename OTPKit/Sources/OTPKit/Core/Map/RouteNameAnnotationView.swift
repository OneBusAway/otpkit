//
//  RouteNameAnnotationView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/28/25.
//

import MapKit
import UIKit

/// Custom annotation view for displaying route names/numbers
class RouteNameAnnotationView: MKAnnotationView {
    private let label = UILabel()
    private let badgeView = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        // Disable callout
        canShowCallout = false

        // Setup badge container view
        badgeView.layer.cornerRadius = 6
        badgeView.layer.masksToBounds = true
        addSubview(badgeView)

        // Setup label
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        badgeView.addSubview(label)

        // Set a default frame size
        frame = CGRect(x: 0, y: 0, width: 40, height: 24)
    }

    func configure(routeName: String, backgroundColor: UIColor?, textColor: UIColor?) {
        label.text = routeName

        // Use provided colors or defaults
        badgeView.backgroundColor = backgroundColor ?? .systemBlue
        label.textColor = textColor ?? .white

        // Size to fit the text with padding
        label.sizeToFit()
        let padding: CGFloat = 8
        let width = max(label.frame.width + padding * 2, 24) // Minimum width of 24
        let height: CGFloat = 20

        badgeView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        label.frame = CGRect(x: padding, y: 0, width: width - padding * 2, height: height)

        // Center the badge in the annotation view
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        centerOffset = CGPoint(x: 0, y: 0)
    }
}
