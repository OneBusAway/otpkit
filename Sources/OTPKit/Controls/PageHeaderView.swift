//
//  PageHeaderView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 7/31/24.
//

import SwiftUI

/// Appears at the top of UI pages with a title and close button.
struct PageHeaderView: View {
    private let text: String
    private let action: VoidBlock?

    init(text: String, action: VoidBlock? = nil) {
        self.text = text
        self.action = action
    }

    var body: some View {
        HStack {
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: {
                action?()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            })
        }
    }
}

#Preview {
    PageHeaderView(text: "Favorites")
}
