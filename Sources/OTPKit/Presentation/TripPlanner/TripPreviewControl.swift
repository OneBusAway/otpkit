//
//  TripPreviewControl.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//

import SwiftUI

/// Control panel for previewing and starting a selected trip itinerary.
public struct TripPreviewControl: View {
    private let itinerary: Itinerary
    private let currentIndex: Int
    private let totalRoutes: Int

    private let onCancel: VoidBlock
    private let onStart: (Itinerary) -> Void

    private let onPreviousRoute: VoidBlock?
    private let onNextRoute: VoidBlock?

    public init(
        itinerary: Itinerary,
        currentIndex: Int = 0,
        totalRoutes: Int = 1,
        onCancel: @escaping VoidBlock,
        onStart: @escaping (Itinerary) -> Void,
        onPreviousRoute: VoidBlock? = nil,
        onNextRoute: VoidBlock? = nil
    ) {
        self.itinerary = itinerary
        self.currentIndex = currentIndex
        self.totalRoutes = totalRoutes
        self.onCancel = onCancel
        self.onStart = onStart
        self.onPreviousRoute = onPreviousRoute
        self.onNextRoute = onNextRoute
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Route summary/title
            Text(itinerary.summary)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Button row for navigation and actions
            HStack(spacing: 12) {
                // Previous Route Button (if multiple routes)
                if totalRoutes > 1 {
                    Button(action: { onPreviousRoute?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(currentIndex > 0 ? Color.blue : Color.secondary.opacity(0.3))
                            )
                    }
                    .disabled(currentIndex <= 0 || onPreviousRoute == nil)
                }
                
                // Cancel Button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                // Start Navigation Button
                Button {
                    onStart(itinerary)
                } label: {
                    Text("Start")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.borderedProminent)
                
                // Next Route Button (if multiple routes)
                if totalRoutes > 1 {
                    Button(action: { onNextRoute?() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(currentIndex < totalRoutes - 1 ? Color.blue : Color.secondary.opacity(0.3))
                                )
                    }
                    .disabled(currentIndex >= totalRoutes - 1 || onNextRoute == nil)
                }
            }
        }
        .padding(16)
        .background(.thickMaterial)
        .animation(.easeInOut(duration: 0.3), value: itinerary)
    }
}
