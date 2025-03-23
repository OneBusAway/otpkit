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
        HStack(spacing: 0) {
            
            // Search Field
            HStack {
                
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray.opacity(0.6))
                
                TextField(placeholder, text: $searchText)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 20, height: 20)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.3), value: isSearchFocused)
            
            // Cancel Button
            Button(action: {
                isSearchFocused = false
                searchText = ""
            }, label: {
                Text("Cancel")
                    .font(.none)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            })
            .padding(.leading, 8)
            .frame(width: isSearchFocused ? 70 : 0, height: 45)
            .animation(.easeInOut(duration: 0.3).delay(0.1), value: isSearchFocused)
            .opacity(isSearchFocused ? 1 : 0)
        }
    }
}

 #Preview {
     @State var text: String = ""
     SearchView(placeholder: "TEST", searchText: $text)
         .padding(.horizontal, 16)
 }
