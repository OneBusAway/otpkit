//
//  SearchView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/11/24.
//

import SwiftUI

/// A reusable Search control suitable for displaying in the header of a view.
struct SearchView: View {
    var placeholder: String
    @Binding var searchText: String
    @FocusState var isSearchFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(placeholder, text: $searchText)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// #Preview {
//    SearchView()
// }
