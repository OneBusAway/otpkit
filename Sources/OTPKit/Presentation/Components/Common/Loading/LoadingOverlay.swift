//
//  LoadingOverlay.swift
//  OTPKit
//
//  Created by Manu on 2025-07-21.
//

import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        VStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .overlay {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))

                        Text("Planning your trip...")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top)
                    }
                }
        }
    }
}

#Preview {
    LoadingOverlay()
}
