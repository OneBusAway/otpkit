//
//  AddFavoriteLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

/// This sheet responsible to add a new favorite location.
/// Users can search and add their favorite locations
public struct AddFavoriteLocationsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner

    // MARK: - ViewModel
    private var viewModel: AddFavoriteLocationsViewModel {
        AddFavoriteLocationsViewModel(
            tripPlannerService: tripPlanner,
            sheetEnvironment: sheetEnvironment,
            userDefaultsService: UserDefaultsServices.shared
        )
    }

    // MARK: - State
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isAllRecentPresented: Bool = false

    // MARK: - Body
    public var body: some View {
        VStack {
            PageHeaderView(text: "Add Favorite") {
                dismiss()
            }
            .padding()

            SearchView(
                placeholder: "Search for a place",
                searchText: $searchText,
                isSearchFocused: _isSearchFocused
            )
            .padding(.horizontal, 16)
            .onChange(of: searchText) { _, newValue in
                viewModel.updateSearchQuery(newValue)
            }

            List {
                if searchText.isEmpty && !isSearchFocused {
                    currentUserSection()
                    recentLocationsSection()
                } else {
                    searchResultsSection()
                }
            }

        }
        .onAppear {
            viewModel.onViewAppear()
        }
        .sheet(isPresented: $isAllRecentPresented) {
            handleRecentLocationSelection()
        } content: {
            MoreRecentLocationsSheet()
        }
        .alert(
            viewModel.currentError?.title ?? "Error",
            isPresented: Binding(
                get: { viewModel.showErrorAlert },
                set: { _ in viewModel.clearError() }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.currentError?.errorDescription ?? "")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
        }
    }

    // MARK: - View Sections

    @ViewBuilder
    private func currentUserSection() -> some View {
        if viewModel.shouldShowCurrentUserSection {
            AddFavoriteCell(
                title: viewModel.currentUserLocation?.title ?? "",
                subtitle: viewModel.currentUserLocation?.subTitle ?? "",
                action: {
                    viewModel.addCurrentUserLocationToFavorites()
                    dismiss()
                }
            )
        }
    }

    @ViewBuilder
    private func recentLocationsSection() -> some View {
        if viewModel.shouldShowRecentLocationsSection {
            Section(content: {
                ForEach(viewModel.limitedRecentLocations) { location in
                    AddFavoriteCell(
                        title: location.title,
                        subtitle: location.subTitle
                    ) {
                        addLocationToFavorites(location)
                    }
                }
            }, header: {
                SectionHeaderView(text: "Recents") {
                    isAllRecentPresented = true
                }
            })
        } else if viewModel.shouldShowNoRecentLocations {
            NoResultsView(
                iconName: "clock",
                title: "No recent locations",
                subtitle: "All recent locations have been added to favorites"
            )
        }
    }

    @ViewBuilder
    private func searchResultsSection() -> some View {
        if viewModel.shouldShowNoSearchResults {
            NoResultsView(
                iconName: "magnifyingglass",
                title: "No results found",
                subtitle: "Try searching for another location"
            )
        } else {
            ForEach(viewModel.filteredCompletions) { location in
                AddFavoriteCell(
                    title: location.title,
                    subtitle: location.subTitle
                ) {
                    addLocationToFavorites(location)
                }
            }
        }
    }

    // MARK: - Actions

    private func addLocationToFavorites(_ location: Location) {
        viewModel.addToFavorites(location)
        dismiss()
    }

    private func handleRecentLocationSelection() {
        if let selectedLocation = sheetEnvironment.selectedRecentLocation,
           !viewModel.favoriteLocations.contains(selectedLocation) {
            addLocationToFavorites(selectedLocation)
        }
        sheetEnvironment.selectedRecentLocation = nil
    }
}

#Preview {
    AddFavoriteLocationsSheet()
}
