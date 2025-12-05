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
    private var currentTitle: String?
    private var currentBorderColor: UIColor?

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

        dotView.backgroundColor = .white
        dotView.layer.cornerRadius = dotSize / 2
        dotView.layer.borderWidth = 2
        dotView.layer.borderColor = UIColor.gray.cgColor
        addSubview(dotView)

        addSubview(label)
    }

    private func updateLabelColors() {
        guard let title = currentTitle else { return }

        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let foregroundColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.9)
            : UIColor.black.withAlphaComponent(0.9)
        let strokeColor = isDarkMode ? UIColor.black : UIColor.white

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "HelveticaNeue-CondensedBold", size: 15) as Any,
            .foregroundColor: foregroundColor,
            .strokeColor: strokeColor,
            .strokeWidth: -4.0  // Negative = fill + stroke
        ]
        label.attributedText = NSAttributedString(string: title, attributes: attributes)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateLabelColors()
        }
    }

    func configure(title: String?, borderColor: UIColor?) {
        currentTitle = title
        currentBorderColor = borderColor
        dotView.layer.borderColor = (borderColor ?? .gray).cgColor
        updateLabelColors()
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

// MARK: - Preview

import SwiftUI

#Preview("Light Mode") {
    IntermediateStopAnnotationPreview(
        title: "24th Ave E & E McGraw St",
        borderColor: .orange
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    IntermediateStopAnnotationPreview(
        title: "24th Ave E & E McGraw St",
        borderColor: .orange
    )
    .preferredColorScheme(.dark)
}

#Preview("Dot Only") {
    IntermediateStopAnnotationPreview(
        title: "24th Ave E & E McGraw St",
        borderColor: .blue,
        showLabel: false
    )
}

private struct IntermediateStopAnnotationPreview: UIViewRepresentable {
    let title: String
    let borderColor: UIColor
    var showLabel: Bool = true

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let annotationView = IntermediateStopAnnotationView(annotation: nil, reuseIdentifier: nil)
        annotationView.configure(title: title, borderColor: borderColor)
        annotationView.updateLabelVisibility(showLabel: showLabel)

        container.addSubview(annotationView)
        annotationView.center = CGPoint(x: 150, y: 30)

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
