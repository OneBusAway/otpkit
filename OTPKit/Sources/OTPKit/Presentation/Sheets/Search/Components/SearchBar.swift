//
//  SearchBar.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    let onSearchTextChange: (String) -> Void

    @FocusState private var isSearchFocused: Bool
    @Environment(\.otpTheme) private var theme

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.secondaryColor)
                .font(.system(size: 16))

            TextField("Search for places", text: $searchText)
                .focused($isSearchFocused)
                .font(.system(size: 16))
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { newValue in
                    onSearchTextChange(newValue)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onSearchTextChange("")
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.secondaryColor)
                        .font(.system(size: 16))
                })
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Preview
struct SearchBar_Previews: PreviewProvider {
    @State static var searchText = ""

    static var previews: some View {
        SearchBar(
            searchText: $searchText,
            onSearchTextChange: { text in
                print("Search text changed: \(text)")
            }
        )
        .padding()
    }
}
