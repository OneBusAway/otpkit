//
//  FavoriteLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

struct FavoriteLocationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment

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
                ForEach(sheetEnvironment.favoriteLocations) { location in
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
