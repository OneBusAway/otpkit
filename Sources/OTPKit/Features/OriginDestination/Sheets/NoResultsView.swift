//
//  NoResultsView.swift
//  OTPKit
//
//  Created by Mohamed Sliem on 21/03/2025.
//


import SwiftUI

struct NoResultsView: View {
    let message: String
    let iconName: String

    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}