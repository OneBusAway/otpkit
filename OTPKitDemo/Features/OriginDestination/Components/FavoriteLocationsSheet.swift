//
//  FavoriteLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

struct FavoriteLocationsSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var mockSavedLocations = [Location(title: "abc", subTitle: "Subtitle 1", latitude: 100, longitude: 120),
                                             Location(title: "def", subTitle: "Subtitle 2", latitude: 10, longitude: 20)]

    var body: some View {
        VStack {
            HStack {
                Text("Favorites")
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

            List {
                ForEach(mockSavedLocations) { location in
                    VStack(alignment: .leading) {
                        Text(location.title)
                            .font(.headline)
                        Text(location.subTitle)
                    }
                }
            }
        }
    }
}

#Preview {
    FavoriteLocationsSheet()
}
