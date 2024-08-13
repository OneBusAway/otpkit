//
//  FlowLayout.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 04/08/24.
//

import SwiftUI

/// Extension to make adaptive layout
struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets

        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let verticalSpacing: CGFloat = 4
        let horizontalSpacing: CGFloat = 8
        var result: [CGPoint] = []
        var currentPosition: CGPoint = .zero
        var maxY: CGFloat = 0

        for size in sizes {
            if currentPosition.x + size.width > (proposal.width ?? .infinity) {
                currentPosition.x = 0
                currentPosition.y = maxY + verticalSpacing
            }
            result.append(currentPosition)
            currentPosition.x += size.width + horizontalSpacing
            maxY = max(maxY, currentPosition.y + size.height)
        }

        return (result, CGSize(width: proposal.width ?? .infinity, height: maxY))
    }
}
