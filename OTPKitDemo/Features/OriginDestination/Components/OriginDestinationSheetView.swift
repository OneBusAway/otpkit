import MapKit
import SwiftUI

/// OriginDestinationSheetView responsible for showing sheets
///  consists of available origin/destination of OriginDestinationView
/// - Attributes:
///     - sheetEnvironment responsible for manage sheet states across the view. See `OriginDestinationSheetEnvironment`
///     - locationService responsible for manage autocompletion of origin/destination search bar. See `LocationService`
///
struct OriginDestinationSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sheetEnvironment: OriginDestinationSheetEnvironment

    @StateObject private var locationService = LocationService()

    @State private var mockSavedLocations = [
        Location(title: "abc", subTitle: "Subtitle 1", latitude: 100, longitude: 120),
        Location(title: "def", subTitle: "Subtitle 2", latitude: 10, longitude: 20)
    ]

    @State private var search: String = ""

    // Sheet States
    @State private var isAddSavedLocationsSheetOpen = false
    @State private var isMoreSavedLocationSheetOpen = false
    @State private var isMoreRecentLocationSheetOpen = false

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
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func favoritesSection() -> some View {
        Section(content: {
            ScrollView(.horizontal) {
                switch UserDefaultsServices.shared.getFavoriteLocationsData() {
                case let .success(favoriteLocations):
                    ForEach(favoriteLocations, content: { location in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(location.title)
                                    .font(.headline)
                                Text(location.subTitle)
                            }
                            Button(action: {
                                isAddSavedLocationsSheetOpen.toggle()
                            }, label: {
                                Image(systemName: "plus")
                                    .padding()
                                    .background(Color.gray.opacity(0.5))
                                    .clipShape(Circle())
                                    .padding()
                            })
                        }

                    })
                case .failure:
                    HStack {
//                        Text("There's no\nfavorite\nlocation")
                        Button(action: {
                            isAddSavedLocationsSheetOpen.toggle()
                        }, label: {
                            Image(systemName: "plus")
                                .padding()
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                                .padding()
                        })
                    }
                }
            }
        }, header: {
            HStack {
                Text("Favorites")
                    .textCase(.none)
                Spacer()
                Button(action: {
                    isMoreSavedLocationSheetOpen.toggle()
                }, label: {
                    Text("More")
                        .textCase(.none)
                        .font(.subheadline)
                })
            }
        })
        .sheet(isPresented: $isAddSavedLocationsSheetOpen, content: {
            AddFavoriteLocationsSheet().environmentObject(locationService)
        })
        .sheet(isPresented: $isMoreSavedLocationSheetOpen, content: {
            FavoriteLocationsSheet()
        })
    }

    private func recentsSection() -> some View {
        switch UserDefaultsServices.shared.getRecentLocations() {
        case let .success(recentLocations):
            return AnyView(
                Section(content: {
                    ForEach(recentLocations, content: { location in
                        VStack(alignment: .leading) {
                            Text(location.title)
                                .font(.headline)
                            Text(location.subTitle)
                        }
                    })
                }, header: {
                    HStack {
                        Text("Recents")
                            .textCase(.none)
                        Spacer()
                        Button(action: {
                            isMoreRecentLocationSheetOpen.toggle()
                        }, label: {
                            Text("More")
                                .textCase(.none)
                                .font(.subheadline)
                        })
                    }
                })
                .sheet(isPresented: $isMoreRecentLocationSheetOpen, content: {
                    RecentLocationsSheet()
                })
            )
        case .failure:
            return AnyView(EmptyView())
        }
    }

    private func searchResultsSection() -> some View {
        ForEach(locationService.completions) { location in
            Button(action: {
                UserDefaultsServices.shared.saveRecentLocations(data: location)
                dismiss()
            }) {
                VStack(alignment: .leading) {
                    Text(location.title)
                        .font(.headline)
                    Text(location.subTitle)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    var body: some View {
        VStack {
            headerView()
                .padding()

            searchView()
                .padding(.horizontal, 16)

            List {
                if search.isEmpty {
                    favoritesSection()
                    recentsSection()
                } else {
                    searchResultsSection()
                }
            }
            .onChange(of: search) { searchValue in
                locationService.update(queryFragment: searchValue)
            }

            Spacer()
        }
    }
}

#Preview {
    OriginDestinationSheetView()
}
