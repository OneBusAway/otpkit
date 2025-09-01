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
    let onLocationSelected: OnLocationSelectedHandler

    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    // MapKit search
    @State private var searchManager = SearchManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.secondaryColor)
                        .font(.system(size: 16))

                    TextField("Search for places", text: $searchText)
                        .focused($isSearchFocused)
                        .font(.system(size: 16))
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            if newValue.isEmpty {
                                searchManager.clear()
                            } else {
                                searchManager.search(query: newValue)
                            }
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            searchManager.clear()
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.secondaryColor)
                                .font(.system(size: 16))
                        })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Search Results
                if isSearching {
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
                } else if searchManager.searchCompletions.isEmpty && !searchText.isEmpty {
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
                } else if !searchManager.searchCompletions.isEmpty {
                    List(searchManager.searchCompletions, id: \.self) { completion in
                        SearchCompletionRow(completion: completion) {
                            performDetailedSearch(for: completion)
                        }
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
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    private func performDetailedSearch(for completion: MKLocalSearchCompletion) {
        isSearching = true

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false

                guard let response = response,
                      let item = response.mapItems.first else {
                    print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let location = Location(
                    title: item.name ?? completion.title,
                    subTitle: item.placemark.title ?? completion.subtitle,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )

                onLocationSelected(location, selectedMode)
            }
        }
    }
}
