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

    let selectedMode: LocationMode
    let onLocationSelected: (Location) -> Void

    @State private var searchText = ""
    @State private var searchResults: [Location] = []

    // Search ViewModel
    @State private var searchViewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(searchText: $searchText) { newValue in
                    if newValue.isEmpty {
                        searchViewModel.clear()
                    } else {
                        searchViewModel.search(query: newValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Search Results
                if searchViewModel.isSearching {
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
                } else if searchViewModel.searchCompletions.isEmpty && !searchText.isEmpty {
                    // Empty state
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
                } else if !searchViewModel.searchCompletions.isEmpty {
                    List(searchViewModel.searchCompletions, id: \.self) { completion in
                        SearchCompletionRow(
                            completion: completion,
                            onTap: {
                                searchViewModel.performDetailedSearch(for: completion, onLocationSelected: onLocationSelected)
                            },
                            onFavoritesTap: { completion in
                                searchViewModel.addToFavorites(completion: completion)
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .padding(.top, 16)
                } else {
                    // Default state
                    VStack(spacing: 24) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(theme.secondaryColor)

                        VStack(spacing: 8) {
                            Text("Search for \(selectedMode == .origin ? "origin" : "destination")")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Enter a place name, address, or landmark")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)

                    Spacer()
                }
            }
            .navigationTitle("Search Places")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

}
