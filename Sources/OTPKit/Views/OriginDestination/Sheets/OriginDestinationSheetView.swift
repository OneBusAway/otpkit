import MapKit
import SwiftUI

/// OriginDestinationSheetView responsible for showing sheets
///  consists of available origin/destination of OriginDestinationView
/// - Attributes:
///     - sheetEnvironment responsible for manage sheet states across the view. See `OriginDestinationSheetEnvironment`
///     - locationService responsible for manage autocompletion of origin/destination search bar. See `LocationService`
///
public struct OriginDestinationSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner

    // MARK: - ViewModel (Lazy initialization)
    private var viewModel: OriginDestinationSheetViewModel {
        OriginDestinationSheetViewModel(
            tripPlannerService: tripPlanner,
            sheetEnvironment: sheetEnvironment,
            userDefaultsService: UserDefaultsServices.shared
        )
    }

    // MARK: - State
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    // MARK: - Sheet States
    private enum Modals: Identifiable {
        case addFavoriteSheet
        case moreFavoritesSheet
        case favoriteDetailsSheet
        case moreRecentsSheet

        var id: Self { self }
    }

    @StateObject private var presentationManager = PresentationManager<Modals>()
    @State private var isShowFavoriteConfirmationDialog = false

    // MARK: - Initialization
    public init() {}

    // MARK: - Body
    public var body: some View {
        VStack {
            PageHeaderView(text: viewModel.pageTitle) {
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
                if searchText.isEmpty && isSearchFocused {
                    currentUserSection()
                } else if searchText.isEmpty {
                    locationSelectionSection()
                    favoritesSection()
                    recentsSection()
                } else {
                    searchResultsSection()
                }
            }

            Spacer()
        }
        .onAppear {
            viewModel.onViewAppear()
        }
        .sheet(item: $presentationManager.activePresentation) { presentation in
            sheetContent(for: presentation)
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
        .confirmationDialog("", isPresented: $isShowFavoriteConfirmationDialog) {
            favoriteSectionConfirmationDialog()
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
        if viewModel.currentUserLocation != nil {
            Button(action: {
                viewModel.selectCurrentUserLocation()
                dismiss()
            }, label: {
                VStack(alignment: .leading) {
                    Text("My Location")
                        .font(.headline)
                    Text("Your current location")
                }
            })
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func locationSelectionSection() -> some View {
        Section(content: {
            selectLocationBasedOnMap()
            currentLocationAsOriginDestination()
        }, header: {
            Text("Select Location")
                .textCase(.none)
        })
    }

    private func selectLocationBasedOnMap() -> some View {
        Button(action: {
            viewModel.selectLocationOnMap()
            dismiss()
        }, label: {
            HStack {
                Image(systemName: "mappin")
                Text("Choose on Map")
            }
        })
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func currentLocationAsOriginDestination() -> some View {
        if viewModel.currentUserLocation != nil {
            Button(action: {
                viewModel.selectCurrentUserLocation()
                dismiss()
            }, label: {
                HStack {
                    Image(systemName: "mappin")
                    Text("Set current location as \(viewModel.currentLocationType.capitalizedName)")
                }
            })
            .buttonStyle(.plain)
        }
    }

    private func favoritesSection() -> some View {
        Section(content: {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.favoriteLocations) { location in
                        FavoriteView(
                            title: location.title,
                            imageName: "mappin",
                            tapAction: {
                                viewModel.selectLocation(location)
                                dismiss()
                            },
                            longTapAction: {
                                isShowFavoriteConfirmationDialog = true
                                sheetEnvironment.selectedDetailFavoriteLocation = location
                            }
                        )
                    }

                    FavoriteView(title: "Add", imageName: "plus", tapAction: {
                        presentationManager.present(.addFavoriteSheet)
                    })
                }
            }
        }, header: {
            SectionHeaderView(text: "Favorites") {
                presentationManager.present(.moreFavoritesSheet)
            }
        })
    }

    @ViewBuilder
    private func recentsSection() -> some View {
        if !viewModel.recentLocations.isEmpty {
            Section(content: {
                ForEach(Array(viewModel.recentLocations.prefix(5))) { location in
                    Button {
                        viewModel.selectLocation(location)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(location.title)
                                .font(.headline)
                            Text(location.subTitle)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }, header: {
                SectionHeaderView(text: "Recents") {
                    presentationManager.present(.moreRecentsSheet)
                }
            })
        }
    }

    private func searchResultsSection() -> some View {
        ForEach(viewModel.filteredCompletions) { location in
            Button(action: {
                viewModel.selectLocation(location)
                dismiss()
            }, label: {
                VStack(alignment: .leading) {
                    Text(location.title)
                        .font(.headline)
                    Text(location.subTitle)
                }
            })
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(for presentation: Modals) -> some View {
        switch presentation {
        case .addFavoriteSheet:
            AddFavoriteLocationsSheet()
        case .moreFavoritesSheet:
            MoreFavoriteLocationsSheet()
        case .favoriteDetailsSheet:
            FavoriteLocationDetailSheet()
        case .moreRecentsSheet:
            MoreRecentLocationsSheet()
        }
    }

    private func favoriteSectionConfirmationDialog() -> some View {
        Group {
            Button(action: {
                presentationManager.present(.favoriteDetailsSheet)
            }, label: {
                Text("Show Details")
            })

            Button(role: .destructive, action: {
                guard let location = sheetEnvironment.selectedDetailFavoriteLocation else { return }
                viewModel.removeFromFavorites(location)
            }, label: {
                Text("Delete")
            })
        }
    }
}

#Preview {
    OriginDestinationSheetView()
}
