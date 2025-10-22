//
//  RecentsSectionView.swift
//  OTPKit
//
//  Created by Manu on 2025-08-28.
//

import SwiftUI
import OSLog

/// A section that displays user's recent locations in a native List format
/// Shows loading state, empty state, and a "More" button in the header
struct RecentsSectionView: View {
    let selectedMode: LocationMode
    let onLocationSelected: (Location) -> Void
    let onMoreTapped: () -> Void

    @Environment(\.otpTheme) private var theme
    @State private var recentLocations: [Location] = []
    @State private var isLoading = true

    private let maxDisplayCount = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            loadRecentLocations()
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        HStack {
            Text("Recents")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()

            if !recentLocations.isEmpty && !isLoading {
                Button("More", action: onMoreTapped)
                    .font(.subheadline)
                    .foregroundColor(theme.primaryColor)
            }
        }
        .padding(.horizontal, 16)
    }

    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
            } else if recentLocations.isEmpty {
                emptyStateView
            } else {
                recentsListView
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 16)
                            .cornerRadius(8)

                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                            .cornerRadius(6)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            Text("No Recent Locations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    private var recentsListView: some View {
        List {
            ForEach(Array(recentLocations.prefix(maxDisplayCount)), id: \.id) { location in
                Button(action: {
                    onLocationSelected(location)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.secondaryColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if !location.subTitle.isEmpty {
                                Text(location.subTitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.visible)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteLocation(location)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .frame(height: CGFloat(min(recentLocations.count, maxDisplayCount)) * 60)
        .scrollDisabled(true)
    }

    // MARK: - Private Methods

    private func loadRecentLocations() {
        isLoading = true

        switch UserDefaultsServices.shared.getRecentLocations() {
        case .success(let locations):
            recentLocations = locations
        case .failure:
            recentLocations = []
        }

        isLoading = false
    }

    private func deleteLocation(_ location: Location) {
        // Optimistically remove from UI first
        recentLocations.removeAll { $0.id == location.id }

        // Then delete from UserDefaults
        let result = UserDefaultsServices.shared.deleteRecentLocation(with: location.id)
        switch result {
        case .success:
            break
        case .failure(let error):
            Logger.main.error("Failed to delete recent location: \(error.localizedDescription)")
            loadRecentLocations()
        }
    }
}

// MARK: - Preview

#Preview {
    RecentsSectionView(
        selectedMode: .destination,
        onLocationSelected: { _ in },
        onMoreTapped: { }
    )
    .padding(.vertical)
    .padding(.horizontal)
}
