//
//  SearchSheetView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//
import SwiftUI
import MapKit

/// A sheet that allows users to search for a location.
/// Integrates with MapKit to fetch and display search suggestions and details.
struct SearchSheetView: View {
    @Environment(\.otpTheme) private var theme
    @Environment(\.otpSearchRegion) private var searchRegion

    let selectedMode: LocationMode
    let onLocationSelected: OnLocationSelectedHandler

    @State private var searchText = ""
    @State private var searchResults: [Location] = []

    // MapKit search - initialized lazily with region from environment
    @State private var searchManager: SearchManager?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(searchText: $searchText) { newValue in
                    guard let manager = searchManager else { return }
                    if newValue.isEmpty {
                        manager.clear()
                    } else {
                        manager.search(query: newValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Search Results
                if let manager = searchManager {
                    if manager.isSearching {
                        buildSearchingView()
                    } else if manager.searchCompletions.isEmpty && !searchText.isEmpty {
                        buildNoSearchResultsView()
                    } else if !manager.searchCompletions.isEmpty {
                        buildSearchResultsView(manager: manager)
                    } else {
                        buildDefaultView()
                    }
                } else {
                    buildDefaultView()
                }
            }
            .navigationTitle(buildNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if searchManager == nil {
                searchManager = SearchManager(region: searchRegion)
            }
        }
    }

    @ViewBuilder
    private func buildDefaultView() -> some View {
        // Default state
        VStack(spacing: 24) {
            CurrentLocationButton { location in
                onLocationSelected(location, selectedMode)
            }

            FavoritesSectionView(selectedMode: selectedMode) { loc in
                onLocationSelected(loc, selectedMode)
            } onMoreTapped: {
                // more tapped
            }

            RecentsSectionView(selectedMode: selectedMode) { loc in
                onLocationSelected(loc, selectedMode)
            } onMoreTapped: {
                // more tapped
            }
        }
        .padding(.top, 20)

        Spacer()
    }

    @ViewBuilder
    private func buildSearchingView() -> some View {
        // Loading state
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(theme.secondaryColor)
        }
        .padding(.top, 60)
        Spacer()
    }

    @ViewBuilder
    private func buildNoSearchResultsView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryColor)

            Text("No results found")
                .font(.headline)
                .foregroundColor(theme.secondaryColor)

            Text("Try searching for a different location")
                .font(.subheadline)
                .foregroundColor(theme.secondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        Spacer()
    }

    @ViewBuilder
    private func buildSearchResultsView(manager: SearchManager) -> some View {
        List(manager.searchCompletions, id: \.self) { completion in
            SearchCompletionRow(completion: completion) {
                manager.performDetailedSearch(for: completion) { location in
                    onLocationSelected(location, selectedMode)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
        .padding(.top, 16)
    }

    private func buildNavigationTitle() -> String {
        switch selectedMode {
        case .origin:
            return "Choose Start"
        case .destination:
            return "Choose Destination"
        }
    }
}

#Preview {
    SearchSheetView(selectedMode: .origin) { _, _ in }
}
