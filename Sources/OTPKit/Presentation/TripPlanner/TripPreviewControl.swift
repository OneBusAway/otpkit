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

    @Environment(\.otpTheme) private var theme
    @State private var isPressed = false

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
        VStack(spacing: 16) {
            // Header with route counter
            VStack(spacing: 8) {
                if totalRoutes > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<totalRoutes, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? theme.primaryColor : Color(.systemGray4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .animation(.spring(response: 0.3), value: currentIndex)
                }

                Text(itinerary.summary)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action buttons
            HStack(spacing: 12) {
                // Navigation buttons (only if multiple routes)
                if totalRoutes > 1 {
                    navigationButton(
                        icon: "chevron.left",
                        isEnabled: currentIndex > 0 && onPreviousRoute != nil,
                        action: { onPreviousRoute?() }
                    )
                }

                // Cancel button
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Start button
                Button {
                    onStart(itinerary)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Start Trip")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: theme.primaryColor.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .scaleEffect(isPressed ? 0.95 : 1.0)

                if totalRoutes > 1 {
                    navigationButton(
                        icon: "chevron.right",
                        isEnabled: currentIndex < totalRoutes - 1 && onNextRoute != nil,
                        action: { onNextRoute?() }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: itinerary)
    }

    // Navigation button helper
    @ViewBuilder
    private func navigationButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isEnabled ? .white : .secondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isEnabled ? theme.primaryColor : Color(.systemGray5))
                        .shadow(
                            color: isEnabled ? theme.primaryColor.opacity(0.3) : .clear,
                            radius: 6,
                            y: 2
                        )
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// Custom button style for scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 30) {
        // Single route
        TripPreviewControl(
            itinerary: PreviewHelpers.buildItin(),
            currentIndex: 0,
            totalRoutes: 1,
            onCancel: { print("canceled") },
            onStart: { it in print(it) }
        )

        // Multiple routes
        TripPreviewControl(
            itinerary: PreviewHelpers.buildItin(),
            currentIndex: 1,
            totalRoutes: 3,
            onCancel: { print("canceled") },
            onStart: { it in print(it) },
            onPreviousRoute: { print("previous") },
            onNextRoute: { print("next") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
