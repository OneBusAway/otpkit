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
    @EnvironmentObject var sheetEnvironment: OriginDestinationSheetEnvironment

    @ObservedObject private var locationManagerService = LocationManagerService.shared

    @State private var search: String = ""

    // Sheet States
    @State private var isAddSavedLocationsSheetOpen = false
    @State private var isFavoriteLocationSheetOpen = false
    @State private var isRecentLocationSheetOpen = false
    @State private var isFavoriteLocationDetailSheetOpen = false

    @FocusState private var isSearchFocused: Bool

    // Public initializer
    public init() {}

    private func headerView() -> some View {
        HStack {
            Text("Change Stop")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            })
        }
    }

    private func searchView() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search for a place", text: $search)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // swiftlint:disable function_body_length
    private func favoritesSection() -> some View {
        Section(content: {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(sheetEnvironment.favoriteLocations, content: { location in
                        FavoriteView(title: location.title, imageName: "mappin") {
                            sheetEnvironment.selectedDetailFavoriteLocation = location
                            isFavoriteLocationDetailSheetOpen.toggle()
                        }
                    })

                    FavoriteView(title: "Add", imageName: "plus") {
                        isAddSavedLocationsSheetOpen.toggle()
                    }
                }
            }
        }, header: {
            SectionHeaderView(text: "Favorites") {
                isFavoriteLocationSheetOpen.toggle()
            }
        })
        .sheet(isPresented: $isAddSavedLocationsSheetOpen, content: {
            AddFavoriteLocationsSheet()
                .environmentObject(sheetEnvironment)
        })
        .sheet(isPresented: $isFavoriteLocationSheetOpen, content: {
            FavoriteLocationsSheet()
                .environmentObject(sheetEnvironment)
        })
        .sheet(isPresented: $isFavoriteLocationDetailSheetOpen, content: {
            FavoriteLocationDetailSheet()
                .environmentObject(sheetEnvironment)
        })
    }

    // swiftlint:enable function_body_length
    private func recentsSection() -> some View {
        guard sheetEnvironment.recentLocations.count > 0 else {
            return AnyView(EmptyView())
        }

        return AnyView(
            Section(content: {
                ForEach(Array(sheetEnvironment.recentLocations.prefix(5)), content: { location in
                    VStack(alignment: .leading) {
                        Text(location.title)
                            .font(.headline)
                        Text(location.subTitle)
                    }
                })
            }, header: {
                SectionHeaderView(text: "Recents") {
                    isRecentLocationSheetOpen.toggle()
                }
            })
            .sheet(isPresented: $isRecentLocationSheetOpen, content: {
                RecentLocationsSheet()
                    .environmentObject(sheetEnvironment)
            })
        )
    }

    private func searchResultsSection() -> some View {
        Group {
            ForEach(locationManagerService.completions) { location in
                Button(action: {
                    locationManagerService.appendMarker(location: location)
                    locationManagerService.addOriginDestinationData()
                    switch UserDefaultsServices.shared.saveRecentLocations(data: location) {
                    case .success:
                        dismiss()
                    case .failure:
                        break
                    }

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
            if let userLocation = locationManagerService.currentLocation {
                Button(action: {
                    locationManagerService.appendMarker(location: userLocation)
                    locationManagerService.addOriginDestinationData()
                    switch UserDefaultsServices.shared.saveRecentLocations(data: userLocation) {
                    case .success:
                        dismiss()
                    case .failure:
                        break
                    }

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
            locationManagerService.toggleMapMarkingMode(true)
            dismiss()
        }, label: {
            HStack {
                Image(systemName: "mappin")
                Text("Choose on Map")
            }
        })
        .buttonStyle(PlainButtonStyle())
    }

    public var body: some View {
        VStack {
            headerView()
                .padding()

            searchView()
                .padding(.horizontal, 16)

            List {
                if search.isEmpty, isSearchFocused {
                    currentUserSection()
                } else if search.isEmpty {
                    selectLocationBasedOnMap()
                    favoritesSection()
                    recentsSection()
                } else {
                    searchResultsSection()
                }
            }
            .onChange(of: search) { _, searchValue in
                locationManagerService.updateQuery(queryFragment: searchValue)
            }

            Spacer()
        }
        .onAppear {
            sheetEnvironment.refreshFavoriteLocations()
            sheetEnvironment.refreshRecentLocations()
        }
    }
}

#Preview {
    OriginDestinationSheetView()
        .environmentObject(OriginDestinationSheetEnvironment())
}
