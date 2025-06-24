//
//  SwiftUIView.swift
//  OTPKit
//
//  Created by Mohamed Sliem on 21/03/2025.
//

import SwiftUI

struct NoResultsView: View {
    
    private let iconName: String
    private let title: String
    private let subtitle: String
    
    init(iconName: String, title: String, subtitle: String) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .foregroundColor(.secondary)
                .padding(.top, 15)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)

    }
}

#Preview {
    List {
        NoResultsView(iconName: "clock", title: "No results found", subtitle: "Try searching for something else")
    }
}
