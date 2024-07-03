//
//  AddFavoriteLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

struct AddFavoriteLocationsSheet: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var locationService: LocationService

    @State private var search = ""

    var body: some View {
        VStack {
            HStack {
                Text("Add favorite location")
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
            .padding()

            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a place", text: $search)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.2))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)

            List {
                ForEach(locationService.completions) { location in
                    VStack(alignment: .leading) {
                        Text(location.title)
                            .font(.headline)
                        Text(location.subTitle)
                    }
                }
            }
            .onChange(of: search) { searchValue in
                locationService.update(queryFragment: searchValue)
            }
        }
    }
}

#Preview {
    AddFavoriteLocationsSheet()
}
