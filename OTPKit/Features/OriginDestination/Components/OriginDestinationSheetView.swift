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

    @StateObject private var locationService = LocationService()

    @State private var search: String = ""

    // Sheet States
    @State private var isAddSavedLocationsSheetOpen = false
    @State private var isFavoriteLocationSheetOpen = false
    @State private var isRecentLocationSheetOpen = false
    @State private var isFavoriteLocationDetailSheetOpen = false

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
                        Button(action: {
                            sheetEnvironment.selectedDetailFavoriteLocation = location
                            isFavoriteLocationDetailSheetOpen.toggle()
                        }, label: {
                            VStack(alignment: .center) {
                                Image(systemName: "mappin")
                                    .frame(width: 48, height: 48)
                                    .background(Color.gray.opacity(0.5))
                                    .clipShape(Circle())

                                Text(location.title)
                                    .frame(width: 64)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(.all, 4)
                            .foregroundStyle(Color.black)
                        })

                    })

                    Button(action: {
                        isAddSavedLocationsSheetOpen.toggle()
                    }, label: {
                        VStack {
                            Image(systemName: "plus")
                                .frame(width: 48, height: 48)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())

                            Text("Add")
                                .foregroundStyle(Color.black)
                        }
                        .padding(.all, 4)
                    })
                }
            }
        }, header: {
            HStack {
                Text("Favorites")
                    .textCase(.none)
                Spacer()
                Button(action: {
                    isFavoriteLocationSheetOpen.toggle()
                }, label: {
                    Text("More")
                        .textCase(.none)
                        .font(.subheadline)
                })
            }
        })
        .sheet(isPresented: $isAddSavedLocationsSheetOpen, content: {
            AddFavoriteLocationsSheet()
                .environmentObject(locationService)
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
        if sheetEnvironment.recentLocations.isEmpty {
            return AnyView(EmptyView())
        } else {
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
                    HStack {
                        Text("Recents")
                            .textCase(.none)
                        Spacer()
                        Button(action: {
                            isRecentLocationSheetOpen.toggle()
                        }, label: {
                            Text("More")
                                .textCase(.none)
                                .font(.subheadline)
                        })
                    }
                })
                .sheet(isPresented: $isRecentLocationSheetOpen, content: {
                    RecentLocationsSheet()
                        .environmentObject(sheetEnvironment)
                })
            )
        }
    }

    private func searchResultsSection() -> some View {
        ForEach(locationService.completions) { location in
            Button(action: {
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

    public var body: some View {
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
        .onAppear {
            sheetEnvironment.refreshFavoriteLocations()
            sheetEnvironment.refreshRecentLocations()
        }
    }
}

#Preview {
    OriginDestinationSheetView()
}
