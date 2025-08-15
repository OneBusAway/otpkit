//
//  ErrorCardModifier.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

struct ErrorCardModifier: ViewModifier {
    let isPresented: Bool
    let message: String
    let onDismiss: () -> Void
    @State private var offset: CGFloat = 1000
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    ErrorCardView(message: message, onDismiss: onDismiss)
                        .offset(y: offset)

                    Spacer()
                }
                .transition(.opacity)
                .onAppear {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
                .onDisappear {
                    offset = 1000
                }
            }
        }
    }
}

extension View {
    func errorCard(
        isPresented: Bool,
        message: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(ErrorCardModifier(
            isPresented: isPresented,
            message: message,
            onDismiss: onDismiss
        ))
    }
} 
