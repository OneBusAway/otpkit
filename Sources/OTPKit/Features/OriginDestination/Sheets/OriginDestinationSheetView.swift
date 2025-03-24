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

    @State private var search: String = ""

    // Sheet States
    private enum Modals: Identifiable {
        case addFavoriteSheet
        case moreFavoritesSheet
        case favoriteDetailsSheet
        case moreRecentsSheet

        var id: Self { self }
    }

    @StateObject private var presentationManager = PresentationManager<Modals>()

    @State private var isShowFavoriteConfirmationDialog = false

    // Alert States
    @State private var isShowErrorAlert = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""

    @FocusState private var isSearchFocused: Bool

    // Public initializer
    public init() {}

    // MARK: - Shared Actions
    private func updateTripPlanner(for location: Location) {
        tripPlanner.appendMarker(location: location)
        tripPlanner.addOriginDestinationData()
    }

    private func onLocationSelection(for location: Location) {
        updateTripPlanner(for: location)
        switch UserDefaultsServices.shared.saveRecentLocations(data: location) {
        case .success:
            dismiss()
        case .failure:
            break
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
                guard let uid = sheetEnvironment.selectedDetailFavoriteLocation?.id else {
                    return
                }
                switch UserDefaultsServices.shared.deleteFavoriteLocationData(with: uid) {
                case .success:
                    sheetEnvironment.selectedDetailFavoriteLocation = nil
                    sheetEnvironment.refreshFavoriteLocations()
                case let .failure(failure):
                    errorTitle = "Failed to Delete Favorite Location"
                    errorMessage = failure.localizedDescription
                    isShowErrorAlert.toggle()
                }
            }, label: {
                Text("Delete")
            })
        }
    }

    private func favoritesSection() -> some View {
        Section(content: {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(sheetEnvironment.favoriteLocations, content: { location in
                        FavoriteView(title: location.title, imageName: "mappin", tapAction: {
                            updateTripPlanner(for: location)
                            dismiss()
                        }, longTapAction: {
                            isShowFavoriteConfirmationDialog = true
                            sheetEnvironment.selectedDetailFavoriteLocation = location
                        })
                    })

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

    private func recentsSection() -> some View {
        guard sheetEnvironment.recentLocations.count > 0 else {
            return AnyView(EmptyView())
        }

        return AnyView(
            Section(content: {
                ForEach(Array(sheetEnvironment.recentLocations.prefix(5)), content: { location in
                    Button {
                        updateTripPlanner(for: location)
                        switch UserDefaultsServices.shared.updateRecentLocations(location) {
                        case .success:
                            dismiss()
                        case .failure:
                            break
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(location.title)
                                .font(.headline)
                            Text(location.subTitle)
                        }
                        .foregroundColor(.primary)
                    }
                })
            }, header: {
                SectionHeaderView(text: "Recents") {
                    presentationManager.present(.moreRecentsSheet)
                }
            })
        )
    }

    private func searchResultsSection() -> some View {
        Group {
            ForEach(tripPlanner.completions) { location in
                Button(action: {
                    onLocationSelection(for: location)
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
    }

    private func currentUserSection() -> some View {
        Group {
            if let userLocation = tripPlanner.currentLocation {
                Button(action: {
                    onLocationSelection(for: userLocation)
                }, label: {
                    VStack(alignment: .leading) {
                        Text("My Location")
                            .font(.headline)
                        Text("Your current location")
                    }
                })
                .buttonStyle(PlainButtonStyle())
            } else {
                EmptyView()
            }
        }
    }

    private func selectLocationBasedOnMap() -> some View {
        Button(action: {
            tripPlanner.toggleMapMarkingMode(true)
            dismiss()
        }, label: {
            HStack {
                Image(systemName: "mappin")
                Text("Choose on Map")
            }
        })
        .buttonStyle(PlainButtonStyle())
    }

    private func currentLocationAsOriginDestination() -> some View {
        Group {
            if let location = tripPlanner.currentLocation {
                Button(action: {
                    onLocationSelection(for: location)
                }, label: {
                    HStack {
                        Image(systemName: "mappin")
                        Text("Set current location as \(tripPlanner.originDestinationState.name.capitalized)")
                    }
                })
                .buttonStyle(.plain)
            } else {
                EmptyView()
            }
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

    public var body: some View {
        VStack {
            PageHeaderView(text: "Choose \(tripPlanner.originDestinationState.name.capitalized)") {
                dismiss()
            }
            .padding()

            SearchView(placeholder: "Search for a place", searchText: $search, isSearchFocused: _isSearchFocused)
                .padding(.horizontal, 16)

            List {
                if search.isEmpty, isSearchFocused {
                    currentUserSection()
                } else if search.isEmpty {
                    locationSelectionSection()
                    favoritesSection()
                    recentsSection()
                } else {
                    searchResultsSection()
                }
            }
            .onChange(of: search) { _, searchValue in
                tripPlanner.updateQuery(queryFragment: searchValue)
            }

            Spacer()
        }
        .onAppear {
            sheetEnvironment.refreshFavoriteLocations()
            sheetEnvironment.refreshRecentLocations()
        }
        .sheet(item: $presentationManager.activePresentation, onDismiss: {

            // Case of more recent sheet
            if let location = sheetEnvironment.selectedRecentLocation {
                updateTripPlanner(for: location)
                sheetEnvironment.selectedRecentLocation = nil

                switch UserDefaultsServices.shared.updateRecentLocations(location) {
                case .success:
                    dismiss()
                case .failure:
                    break
                }
            } else if let location = sheetEnvironment.selectedFavoriteLocation {
                updateTripPlanner(for: location)
                sheetEnvironment.selectedFavoriteLocation = nil
                dismiss()
            }

        }, content: { presentation in
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
        })
        .alert(isPresented: $isShowErrorAlert) {
            Alert(title: Text(errorTitle),
                  message: Text(errorMessage),
                  dismissButton: .cancel(Text("OK")))
        }
        .confirmationDialog("", isPresented: $isShowFavoriteConfirmationDialog, actions: {
            favoriteSectionConfirmationDialog()
        })
    }
}

#Preview {
    OriginDestinationSheetView()
}
