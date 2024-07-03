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
        SavedLocation(title: "abc", subTitle: "Subtitle 1", latitude: 100, longitude: 120),
        SavedLocation(title: "def", subTitle: "Subtitle 2", latitude: 10, longitude: 20)
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
                HStack {
                    // TODO: Add recent content logics
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
        Section(content: {
            // TODO: Add recent content logics
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
    }

    private func searchResultsSection() -> some View {
        ForEach(locationService.completions) { location in
            VStack(alignment: .leading) {
                Text(location.title)
                    .font(.headline)
                Text(location.subTitle)
            }
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
