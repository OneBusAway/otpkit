//
//  FavoritesSectionView.swift
//  OTPKit
//
//  Created by Manu on 2025-08-28.
//

import SwiftUI

/// A horizontal scrolling section that displays user's favorite locations with circular icons
/// Shows loading state, empty state, and a "More" button when there are favorites
struct FavoritesSectionView: View {
    let selectedMode: LocationMode
    let onLocationSelected: (Location) -> Void
    let onMoreTapped: () -> Void

    @Environment(\.otpTheme) private var theme
    @State private var favoriteLocations: [Location] = []
    @State private var isLoading = true

    private let maxDisplayCount = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            loadFavoriteLocations()
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        HStack {
            Text("Favorites")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
            } else if favoriteLocations.isEmpty {
                emptyStateView
            } else {
                favoritesScrollView
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)

                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 12)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            Text("No Favorites")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var favoritesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                favoriteLocationButtons
                moreButton
            }
            .padding(.horizontal, 16)
        }
    }

    private var favoriteLocationButtons: some View {
        ForEach(Array(favoriteLocations.prefix(maxDisplayCount - 1).enumerated()), id: \.element.id) { _, location in
            FavoriteLocationCircle(location: location) {
                onLocationSelected(location)
            }
        }
    }

    private var moreButton: some View {
        Button(action: onMoreTapped) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)

                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text("More")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Private Methods

    private func loadFavoriteLocations() {
        isLoading = true

        switch UserDefaultsServices.shared.getFavoriteLocationsData() {
        case .success(let locations):
            favoriteLocations = locations
        case .failure:
            favoriteLocations = []
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    FavoritesSectionView(
        selectedMode: .destination,
        onLocationSelected: { _ in },
        onMoreTapped: { }
    )
    .padding(.vertical)
    .padding(.horizontal)
}
