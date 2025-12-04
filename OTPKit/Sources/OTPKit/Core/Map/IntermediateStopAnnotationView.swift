//
//  IntermediateStopAnnotationView.swift
//  OTPKit
//
//  Created by OTPKit on 2025-12-04.
//

import MapKit
import UIKit

/// Custom annotation view for displaying intermediate transit stops as small dots with labels
class IntermediateStopAnnotationView: MKAnnotationView {
    private let dotView = UIView()
    private let label = UILabel()
    private let dotSize: CGFloat = 10

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        canShowCallout = false

        // Setup dot
        dotView.backgroundColor = .white
        dotView.layer.cornerRadius = dotSize / 2
        dotView.layer.borderWidth = 2
        dotView.layer.borderColor = UIColor.gray.cgColor
        addSubview(dotView)

        // Setup label - dark gray on white shadow (Apple Maps style)
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .darkGray
        label.shadowColor = .white
        label.shadowOffset = CGSize(width: 1, height: 1)
        addSubview(label)
    }

    func configure(title: String?, borderColor: UIColor?) {
        dotView.layer.borderColor = (borderColor ?? .gray).cgColor
        label.text = title
        label.sizeToFit()

        // Layout: dot on left, label to the right with spacing
        let spacing: CGFloat = 6
        let totalWidth = dotSize + spacing + label.frame.width

        frame = CGRect(x: 0, y: 0, width: totalWidth, height: max(dotSize, label.frame.height))
        dotView.frame = CGRect(x: 0, y: (frame.height - dotSize) / 2, width: dotSize, height: dotSize)
        label.frame = CGRect(x: dotSize + spacing, y: 0, width: label.frame.width, height: frame.height)

        // Center on the dot position
        centerOffset = CGPoint(x: (totalWidth - dotSize) / 2, y: 0)
    }

    /// Updates label visibility based on zoom level
    /// - Parameter showLabel: Whether to show the label
    func updateLabelVisibility(showLabel: Bool) {
        label.isHidden = !showLabel

        if showLabel {
            // Full width with label
            let spacing: CGFloat = 6
            let totalWidth = dotSize + spacing + label.frame.width
            frame = CGRect(x: 0, y: 0, width: totalWidth, height: max(dotSize, label.frame.height))
            centerOffset = CGPoint(x: (totalWidth - dotSize) / 2, y: 0)
        } else {
            // Just the dot
            frame = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
            dotView.frame = bounds
            centerOffset = CGPoint(x: 0, y: 0)
        }
    }
}
