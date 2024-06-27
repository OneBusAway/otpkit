//
//  OriginDestinationSheetView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import SwiftUI

struct OriginDestinationSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sheetEnvironment: OriginDestinationSheetEnvironment
    // 1
    @StateObject private var locationService = LocationService()
    @State private var search: String = ""

    var body: some View {
        VStack {
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
            .padding()

            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a restaurant", text: $search)
                    .autocorrectionDisabled()
            }
            .padding([.top, .bottom], 8)
            .padding([.leading, .trailing], 12)
            .background(Color.gray.opacity(0.2))
            .clipShape(.rect(cornerRadius: 12))
            .padding([.leading, .trailing], 16)

            Spacer()

            List {
                ForEach(locationService.completions) { completion in
                    Button(action: {}, label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.headline)
                            Text(completion.subTitle)
                        }
                    })
                    // 3
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: search) { newValue in
                locationService.update(queryFragment: newValue)
            }
            .padding()
        }
    }
}

#Preview {
    OriginDestinationSheetView()
}
