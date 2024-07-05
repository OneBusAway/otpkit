//
//  FavoriteLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

/// Show all the lists of favorite locations
public struct FavoriteLocationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment

    @State private var isDetailSheetOpened = false

    public var body: some View {
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
                    Button(action: {
                        sheetEnvironment.selectedDetailFavoriteLocation = location
                        isDetailSheetOpened.toggle()
                    }, label: {
                        VStack(alignment: .leading) {
                            Text(location.title)
                                .font(.headline)
                            Text(location.subTitle)
                        }
                        .foregroundStyle(Color.black)
                    })
                }
            }
            .sheet(isPresented: $isDetailSheetOpened, content: {
                FavoriteLocationDetailSheet()
                    .environmentObject(sheetEnvironment)
            })
        }
    }
}

#Preview {
    FavoriteLocationsSheet()
}
