//
//  OriginDestinationSheetView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import SwiftUI
import MapKit

struct OriginDestinationSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sheetEnvironment: OriginDestinationSheetEnvironment
    
    // 1
    @StateObject private var locationService = LocationService()
    @State private var search: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a restaurant", text: $search)
                    .autocorrectionDisabled()
            }
            .padding()
            
            Spacer()
            
            List {
                ForEach(locationService.completions) { completion in
                    Button(action: { }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.headline)
                            Text(completion.subTitle)
                        }
                    }
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
