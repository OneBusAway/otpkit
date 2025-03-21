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
        VStack {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 50, height: 50)
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .padding()
            
            Text(title)
                .font(.title)
                .foregroundColor(.black)
                .padding()
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}
