//
//  OriginDestinationSheetView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import SwiftUI

/// OriginDestinationSheetView responsible for showing sheets
///  consists of available origin/destination of OriginDestinationView
/// - Attributes:
///     - sheetEnvironment responsible for manage sheet states accross the view. See `OriginDestinationSheetEnvironment`
///     - locationService responsible for manage autocompletion of origin/destination  search bar. See `LocationService`
struct OriginDestinationSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sheetEnvironment: OriginDestinationSheetEnvironment

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
                TextField("Search for a place", text: $search)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.2))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)

            Spacer()

            List {
                ForEach(locationService.completions) { completion in
                    Button(action: {
                        sheetEnvironment.selectedValue = completion.title
                        dismiss()
                    }, label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completion.title)
                                    .font(.headline)
                                Text(completion.subTitle)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    })
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
